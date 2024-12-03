.data
    space: .asciiz " "          # Space character for printing between numbers
    newline: .asciiz "\n"       # Newline character
    extra_newline: .asciiz "\n\n" # Extra newline at end

    # Define board dimensions
    board_width: .word 10        # Example: 10 columns
    board_height: .word 10       # Example: 10 rows

    # Define the board as a 10x10 grid initialized to 0 (empty)
    board: .space 100             # 10 rows * 10 columns = 100 bytes

    # Mapping from ship_num to display character (optional, not used in printBoard)
    ship_chars: .byte '.', 'A', 'B', 'C', 'D', 'E'

.text
.globl zeroOut 
.globl place_tile 
.globl printBoard 
.globl placePieceOnBoard 
.globl test_fit 

# Function: zeroOut
# Arguments: None
# Returns: void
zeroOut:
    # Function prologue

zero_done:
    # Function epilogue
    jr $ra

# Function: placePieceOnBoard
# Arguments: 
#   $a0 - address of piece struct
#   $a1 - ship_num
placePieceOnBoard:
    # Function prologue

    # Load piece fields
    # First switch on type
    li $t0, 1
    beq $s3, $t0, piece_square
    li $t0, 2
    beq $s3, $t0, piece_line
    li $t0, 3
    beq $s3, $t0, piece_reverse_z
    li $t0, 4
    beq $s3, $t0, piece_L
    li $t0, 5
    beq $s3, $t0, piece_z
    li $t0, 6
    beq $s3, $t0, piece_reverse_L
    li $t0, 7
    beq $s3, $t0, piece_T
    j piece_done       # Invalid type

piece_done:
    jr $ra
# Function: printBoard
# Arguments: None (uses global variables)
# Returns: void
# Uses global variables: board (char[]), board_width (int), board_height (int)

printBoard:
    # Function prologue
    addi $sp, $sp, -8          # Allocate stack space for $ra and $s0
    sw $ra, 4($sp)             # Save return address
    sw $s0, 0($sp)             # Save $s0 (if used; optional here)

    # Load board dimensions
    lw $t6, board_height       # $t6 = board_height
    lw $t7, board_width        # $t7 = board_width

    # Initialize row counter to 0
    li $t0, 0                  # $t0 = row = 0

row_loop:
    beq $t0, $t6, end_printBoard    # If row == board_height, exit

    # Initialize column counter to 0
    li $t1, 0                  # $t1 = col = 0

col_loop:
    beq $t1, $t7, print_newline      # If col == board_width, print newline

    # Calculate index = row * board_width + col
    mul $t2, $t0, $t7          # $t2 = row * board_width
    add $t2, $t2, $t1          # $t2 = row * board_width + col

    # Load the number from board[index]
    la $t3, board              # $t3 = address of board
    add $t3, $t3, $t2          # $t3 = &board[index]
    lb $t4, 0($t3)             # $t4 = board[index]

    # Convert to ASCII by adding '0' (48)
    addi $t5, $t4, 48          # $t5 = ASCII character

    # Print the character
    move $a0, $t5              # $a0 = character to print
    li $v0, 11                 # syscall 11 = print_char
    syscall

    # Print space for readability
    la $a0, space              # Load address of space
    li $v0, 4                  # syscall 4 = print_string
    syscall

    # Increment column
    addi $t1, $t1, 1            # col++

    j col_loop                 # Repeat for next column

print_newline:
    # Print newline after each row
    la $a0, newline            # Load address of newline
    li $v0, 4                  # syscall 4 = print_string
    syscall

    # Increment row
    addi $t0, $t0, 1            # row++

    j row_loop                 # Repeat for next row

end_printBoard:
    # Optionally print extra newline for spacing
    la $a0, extra_newline      # Load address of extra_newline
    li $v0, 4                  # syscall 4 = print_string
    syscall

    # Function epilogue
    lw $ra, 4($sp)              # Restore return address
    lw $s0, 0($sp)              # Restore $s0 (if used; optional here)
    addi $sp, $sp, 8            # Deallocate stack space
    jr $ra                      # Return to caller
    
# Function: place_tile
# Arguments: 
#   $a0 - row
#   $a1 - col
#   $a2 - value
# Returns:
#   $v0 - 0 if successful, 1 if occupied, 2 if out of bounds
# Uses global variables: board (char[]), board_width (int), board_height (int)

place_tile:
    jr $ra

# Function: test_fit
# Arguments: 
#   $a0 - address of piece array (5 pieces)
test_fit:
    # Function prologue
    jr $ra


T_orientation4:
    # Study the other T orientations in skeleton.asm to understand how to write this label/subroutine
    j piece_done

.include "skeleton.asm"