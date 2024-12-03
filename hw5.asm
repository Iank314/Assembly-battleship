.data
space: .asciiz " "    # Space character for printing between numbers
newline: .asciiz "\n" # Newline character
extra_newline: .asciiz "\n\n" # Extra newline at end

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
    # Function Prologue
    addi $sp, $sp, -16        # Allocate stack space (4 words)
    sw   $ra, 12($sp)          # Save return address
    sw   $s0, 8($sp)           # Save $s0
    sw   $s1, 4($sp)           # Save $s1
    sw   $s2, 0($sp)           # Save $s2

    # Initialize loop counters
    li   $s0, 0                # $s0 = row = 0

outer_loop:
    # Load board_height to compare with row
    lw   $t0, board_height     # Load board_height into $t0
    beq  $s0, $t0, end_printBoard  # If row == board_height, exit loop

    li   $s1, 0                # $s1 = col = 0

inner_loop:
    # Load board_width to compare with col
    lw   $t1, board_width      # Load board_width into $t1
    beq  $s1, $t1, print_newline   # If col == board_width, print newline

    # Calculate index = row * board_width + col
    mul  $t2, $s0, $t1         # $t2 = row * board_width
    add  $t2, $t2, $s1         # $t2 = row * board_width + col

    # Load the character from board[index]
    la   $t3, board            # Load address of board into $t3
    lb   $t4, 0($t3)            # Load the first byte of board
    # Since MIPS doesn't have a direct indexing mode, calculate address:
    sll  $t5, $t2, 0            # $t5 = index * 1 (since each element is a byte)
    add  $t5, $t5, $t3          # $t5 = board + index
    lb   $t4, 0($t5)            # Load byte at board[index]

    # Print the character
    move $a0, $t4               # Move character to $a0
    li   $v0, 11                # Syscall 11: Print character
    syscall

    # Print a space after the character
    la   $a0, space             # Load address of space
    li   $v0, 4                 # Syscall 4: Print string
    syscall

    addi $s1, $s1, 1            # col++

    j    inner_loop             # Repeat inner loop

print_newline:
    # Print newline after each row
    la   $a0, newline           # Load address of newline
    li   $v0, 4                 # Syscall 4: Print string
    syscall

    addi $s0, $s0, 1            # row++

    j    outer_loop             # Repeat outer loop

end_printBoard:
    # Print extra newline for better formatting (optional)
    la   $a0, extra_newline     # Load address of extra_newline
    li   $v0, 4                 # Syscall 4: Print string
    syscall

    # Function Epilogue
    lw   $ra, 12($sp)           # Restore return address
    lw   $s0, 8($sp)            # Restore $s0
    lw   $s1, 4($sp)            # Restore $s1
    lw   $s2, 0($sp)            # Restore $s2
    addi $sp, $sp, 16           # Deallocate stack space

    jr   $ra                    # Return to caller



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