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
# Uses global variables: board (char[]), board_width (int), board_height (int)
zeroOut:
    # Function Prologue
    addi $sp, $sp, -16         # Allocate stack space (4 words)
    sw   $ra, 12($sp)          # Save return address
    sw   $s0, 8($sp)           # Save $s0 (row counter)
    sw   $s1, 4($sp)           # Save $s1 (column counter)
    sw   $s2, 0($sp)           # Save $s2 (board_width)

    # Load board_width and board_height once
    lw   $s2, board_width      # $s2 = board_width (e.g., 5)
    lw   $s3, board_height     # $s3 = board_height (e.g., 5)

    li   $s0, 0                # Initialize row counter ($s0) to 0

outer_zero_loop:
    # Compare row counter with board_height
    beq  $s0, $s3, end_zeroOut   # If row == board_height, exit loop

    li   $s1, 0                # Initialize column counter ($s1) to 0

inner_zero_loop:
    # Compare column counter with board_width
    beq  $s1, $s2, zero_newline  # If col == board_width, move to next row

    # Calculate index = row * board_width + col
    mul  $t0, $s0, $s2         # $t0 = row * board_width
    add  $t0, $t0, $s1         # $t0 = row * board_width + col

    # Load the base address of board
    la   $t1, board            # Load address of board into $t1

    # Calculate the address of board[index]
    add  $t1, $t1, $t0         # $t1 = board + index

    # Store 0 to board[index]
    sb   $zero, 0($t1)         # board[index] = 0

    # Increment column counter
    addi $s1, $s1, 1           # col++

    j    inner_zero_loop        # Repeat inner loop

zero_newline:
    # After completing a row, optionally perform actions (none needed here)
    addi $s0, $s0, 1            # row++

    j    outer_zero_loop        # Repeat outer loop

end_zeroOut:
    # Function Epilogue
    lw   $ra, 12($sp)          # Restore return address
    lw   $s0, 8($sp)           # Restore $s0 (row counter)
    lw   $s1, 4($sp)           # Restore $s1 (column counter)
    lw   $s2, 0($sp)           # Restore $s2 (board_width)
    addi $sp, $sp, 16          # Deallocate stack space

    jr   $ra                   # Return to caller




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
    addi $sp, $sp, -16         # Allocate stack space (4 words)
    sw   $ra, 12($sp)          # Save return address
    sw   $s0, 8($sp)           # Save $s0 (row counter)
    sw   $s1, 4($sp)           # Save $s1 (column counter)
    sw   $s2, 0($sp)           # Save $s2 (board_width)

    # Load board_width and board_height once
    lw   $s2, board_width      # $s2 = board_width
    lw   $s3, board_height     # $s3 = board_height

    li   $s0, 0                # Initialize row counter ($s0) to 0

outer_loop:
    # Compare row counter with board_height
    beq  $s0, $s3, end_printBoard  # If row == board_height, exit loop

    li   $s1, 0                # Initialize column counter ($s1) to 0

inner_loop:
    # Compare column counter with board_width
    beq  $s1, $s2, print_newline    # If col == board_width, print newline

    # Calculate index = row * board_width + col
    mul  $t0, $s0, $s2         # $t0 = row * board_width
    add  $t0, $t0, $s1         # $t0 = row * board_width + col

    # Load the numerical byte from board[index]
    la   $t1, board            # Load address of board into $t1
    add  $t1, $t1, $t0         # $t1 = board + index
    lb   $t2, 0($t1)           # Load byte at board[index] into $t2

    # Convert numerical byte to ASCII character by adding 48 ('0')
    addi $t2, $t2, 48          # $t2 = $t2 + '0'

    # Print the character
    move $a0, $t2              # Move character to $a0
    li   $v0, 11               # Syscall 11: Print character
    syscall

    # Print a space after the character
    la   $a0, space            # Load address of space into $a0
    li   $v0, 4                # Syscall 4: Print string
    syscall

    addi $s1, $s1, 1           # Increment column counter ($s1)
    j    inner_loop            # Repeat inner loop

print_newline:
    # Print newline after each row
    la   $a0, newline          # Load address of newline into $a0
    li   $v0, 4                # Syscall 4: Print string
    syscall

    addi $s0, $s0, 1           # Increment row counter ($s0)
    j    outer_loop            # Repeat outer loop

end_printBoard:
    # Print extra newline for better formatting (optional)
    la   $a0, extra_newline    # Load address of extra_newline into $a0
    li   $v0, 4                # Syscall 4: Print string
    syscall

    # Function Epilogue
    lw   $ra, 12($sp)          # Restore return address
    lw   $s0, 8($sp)           # Restore $s0
    lw   $s1, 4($sp)           # Restore $s1
    lw   $s2, 0($sp)           # Restore $s2
    addi $sp, $sp, 16          # Deallocate stack space

    jr   $ra                   # Return to caller




# Function: place_tile
# Arguments:
#   $a0 - row
#   $a1 - col
#   $a2 - value
# Returns:
#   $v0 - 0 if successful, 1 if occupied, 2 if out of bounds
# Uses global variables: board (char[]), board_width (int), board_height (int)
place_tile:
    # Function Prologue
    addi $sp, $sp, -16         # Allocate stack space (4 words)
    sw   $ra, 12($sp)          # Save return address
    sw   $s0, 8($sp)           # Save $s0 (row counter)
    sw   $s1, 4($sp)           # Save $s1 (column counter)
    sw   $s2, 0($sp)           # Save $s2 (board_width)

    # Load board_width and board_height
    lw   $s2, board_width      # $s2 = board_width
    lw   $s3, board_height     # $s3 = board_height

    # Move arguments to saved registers for clarity
    move $s0, $a0              # $s0 = row
    move $s1, $a1              # $s1 = col
    move $s4, $a2              # $s4 = value (additional saved register if needed)

    # Bounds Checking: Check if row < 0 or row >= board_height
    bltz $s0, out_of_bounds    # If row < 0, jump to out_of_bounds
    bge  $s0, $s3, out_of_bounds  # If row >= board_height, jump to out_of_bounds

    # Bounds Checking: Check if col < 0 or col >= board_width
    bltz $s1, out_of_bounds    # If col < 0, jump to out_of_bounds
    bge  $s1, $s2, out_of_bounds  # If col >= board_width, jump to out_of_bounds

    # Calculate index = row * board_width + col
    mul  $t0, $s0, $s2         # $t0 = row * board_width
    add  $t0, $t0, $s1         # $t0 = row * board_width + col

    # Load base address of board
    la   $t1, board            # $t1 = address of board

    # Calculate address of board[index]
    add  $t1, $t1, $t0         # $t1 = board + index

    # Load current value at board[index]
    lb   $t2, 0($t1)           # $t2 = board[index]

    # Check if the cell is occupied (non-zero)
    beq  $t2, $zero, place_value  # If board[index] == 0, proceed to place value
    li   $v0, 1                # Set return value to 1 (occupied)
    j    place_tile_done       # Jump to function epilogue

place_value:
    # Place the value into board[index]
    sb   $s4, 0($t1)           # board[index] = value

    li   $v0, 0                # Set return value to 0 (successful)

place_tile_done:
    # Function Epilogue
    lw   $ra, 12($sp)          # Restore return address
    lw   $s0, 8($sp)           # Restore $s0 (row counter)
    lw   $s1, 4($sp)           # Restore $s1 (column counter)
    lw   $s2, 0($sp)           # Restore $s2 (board_width)
    addi $sp, $sp, 16          # Deallocate stack space

    jr   $ra                   # Return to caller

out_of_bounds:
    li   $v0, 2                # Set return value to 2 (out of bounds)
    j    place_tile_done       # Jump to function epilogue






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