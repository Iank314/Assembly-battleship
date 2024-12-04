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
# $v0 - 0 if successful, 1 if occupied, 2 if out of bounds
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
    li   $v0, 1                   # Set return value to 1 (occupied)
    j    place_tile_done          # Jump to function epilogue

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



T_orientation4:
    # Place the center tile of the T (middle of the horizontal bar)
    move $a0, $s5
    addi $a0, $a0, 1       # row + 1 (one row down)
    move $a1, $s6
    addi $a1, $a1, 0       # col (one column left adjustment already handled)
    move $a2, $s1          # ship_num
    jal place_tile          # place the center tile
    or $s2, $s2, $v0       # track error

    # Place the vertical tile above the center
    move $a0, $s5
    addi $a0, $a0, 0       # row (one row up from center)
    move $a1, $s6
    addi $a1, $a1, 0       # col (aligned with adjusted center)
    move $a2, $s1
    jal place_tile          # place the vertical tile above
    or $s2, $s2, $v0       # track error

    # Place the vertical tile below the center
    move $a0, $s5
    addi $a0, $a0, 2       # row + 2 (one row below adjusted center)
    move $a1, $s6
    addi $a1, $a1, 0       # col (aligned with adjusted center)
    move $a2, $s1
    jal place_tile         # place the vertical tile below
    or $s2, $s2, $v0       # track error

    # Place the horizontal tile to the right of the center
    move $a0, $s5
    addi $a0, $a0, 1       # row + 1 (same row as adjusted center)
    move $a1, $s6
    addi $a1, $a1, 1       # col + 1 (directly right of adjusted center)
    move $a2, $s1
    jal place_tile         # place the horizontal tile to the right
    or $s2, $s2, $v0       # track error

    j piece_done            # jump to piece_done label








# Function: placePieceOnBoard
# Arguments:
#   $a0 - address of piece struct
#   $a1 - ship_num
# Returns:
#   $v0 - 0 if successful, 1 if occupied, 2 if out of bounds, 3 if both errors occur.
# Uses global variables: board (char[]), board_width (int), board_height (int)


placePieceOnBoard:
    # Function prologue
    addi $sp, $sp, -16         # Allocate stack space
    sw   $ra, 12($sp)          # Save return address
    sw   $s3, 8($sp)           # Save $s3
    sw   $s4, 4($sp)           # Save $s4
    sw   $s2, 0($sp)           # Save $s2

    # Check alignment of $a0
    andi $t0, $a0, 3           # Check alignment of $a0
    bne  $t0, $zero, piece_invalid_type  # If not aligned, handle as invalid type

    # Initialize tracking error register
    li   $s2, 0                # $s2 = 0 (no errors initially)

    # Load piece fields from struct pointed to by $a0
    lw   $s3, 0($a0)           # $s3 = type
    lw   $s4, 4($a0)           # $s4 = orientation
    lw   $s5, 8($a0)           # $s5 = row location
    lw   $s6, 12($a0)          # $s6 = column location
    move $s1, $a1              # $s1 = ship_num (value to place in board)

    # Branch to the appropriate piece placement subroutine
    li   $t0, 1
    beq  $s3, $t0, piece_square
    li   $t0, 2
    beq  $s3, $t0, piece_line
    li   $t0, 3
    beq  $s3, $t0, piece_reverse_z
    li   $t0, 4
    beq  $s3, $t0, piece_L
    li   $t0, 5
    beq  $s3, $t0, piece_z
    li   $t0, 6
    beq  $s3, $t0, piece_reverse_L
    li   $t0, 7
    beq  $s3, $t0, piece_T
    j    piece_invalid_type    # Invalid type

piece_done:
    # Check for both errors simultaneously
    li   $t0, 3                   # Check if both bits (occupied and out of bounds) are set
    and  $t1, $s2, $t0
    beq  $t1, $t0, mixed_error    # If both errors, go to mixed_error

    # Check if only occupied error occurred
    li   $t0, 1
    and  $t1, $s2, $t0
    bne  $t1, $zero, return_occupied

    # Check if only out-of-bounds error occurred
    li   $t0, 2
    and  $t1, $s2, $t0
    bne  $t1, $zero, return_out_of_bounds

success:
    li   $v0, 0                    # Return 0 for successful placement
    j    return_from_function      # Skip zeroOut on success

mixed_error:
    li   $v0, 3                    # Return 3 for both errors
    j    piece_cleanup

return_occupied:
    li   $v0, 1                    # Return 1 for occupied error
    j    piece_cleanup

return_out_of_bounds:
    li   $v0, 2                    # Return 2 for out-of-bounds error
    j    piece_cleanup

piece_cleanup:
    jal  zeroOut                   # Reset the board
    j    return_from_function

piece_invalid_type:
    li   $v0, -1                   # Return -1 for invalid type
    j    piece_cleanup

return_from_function:
    # Function epilogue
    lw   $ra, 12($sp)              # Restore return address
    lw   $s3, 8($sp)               # Restore $s3
    lw   $s4, 4($sp)               # Restore $s4
    lw   $s2, 0($sp)               # Restore $s2
    addi $sp, $sp, 16              # Deallocate stack space
    jr   $ra                       # Return to caller




# Function: test_fit
# Arguments:
#   $a0 - address of piece array (5 pieces)
#   $v0 - 0 if successful, 1 if occupied, 2 if out of bounds, 3 if both errors occur, 4 if either the type or orientation is out of bounds.
# Uses global variables: board (char[]), board_width (int) board_height (int)

test_fit:
    # Function Prologue
    addi $sp, $sp, -16          # Allocate stack space
    sw   $ra, 12($sp)           # Save return address
    sw   $s0, 8($sp)            # Save $s0 (loop counter)
    sw   $s1, 4($sp)            # Save $s1 (ship struct address)
    sw   $s2, 0($sp)            # Save $s2 (error tracker)

    li   $s0, 0                 # Initialize loop counter to 0
    move $s1, $a0               # $s1 points to the start of the array of ships
    li   $s2, 0                 # Reset error tracker

validate_loop:
    # Validate ship types and orientations
    li   $t0, 5                 # Number of ships
    beq  $s0, $t0, place_ships  # If all ships validated, proceed to placement

    # Load ship type and orientation
    lw   $t1, 0($s1)            # Load type
    lw   $t2, 4($s1)            # Load orientation

    # Check if type is invalid
    li   $t3, 1
    blt  $t1, $t3, return_error_4  # If type < 1, return 4
    li   $t3, 7
    bgt  $t1, $t3, return_error_4  # If type > 7, return 4

    # Check if orientation is invalid
    li   $t3, 1
    blt  $t2, $t3, return_error_4  # If orientation < 1, return 4
    li   $t3, 4
    bgt  $t2, $t3, return_error_4  # If orientation > 4, return 4

    # Move to the next ship
    addi $s1, $s1, 16           # Move to the next ship struct
    addi $s0, $s0, 1            # Increment loop counter
    j    validate_loop

place_ships:
    # Reset loop counter and pointer
    li   $s0, 0
    move $s1, $a0               # Reset $s1 to start of the array

place_loop:
    # Attempt to place each ship
    li   $t0, 5                 # Number of ships
    beq  $s0, $t0, finalize_test_fit  # If all ships placed, finalize

    # Call placePieceOnBoard for the current ship
    move $a0, $s1               # Address of the current ship struct
    addi $a1, $s0, 1            # Ship number (1-based)
    jal  placePieceOnBoard      # Call placePieceOnBoard

    # Track errors based on $v0
    li   $t0, 3                 # Load 3 into $t0
    beq  $v0, $t0, set_error_3  # If $v0 == 3, set error 3 and skip further checks

    li   $t0, 2                 # Load 2 into $t0
    beq  $v0, $t0, set_error_2  # If $v0 == 2, set error 2

    li   $t0, 1                 # Load 1 into $t0
    beq  $v0, $t0, set_error_1  # If $v0 == 1, set error 1
    j    next_ship              # No error, continue to next ship

set_error_3:
    li   $s2, 3                 # Set both errors
    j    next_ship

set_error_2:
    ori  $s2, $s2, 2            # Set out-of-bounds error
    j    next_ship

set_error_1:
    ori  $s2, $s2, 1            # Set overlap error

next_ship:
    # Move to the next ship
    addi $s1, $s1, 16           # Move to the next ship struct
    addi $s0, $s0, 1            # Increment loop counter
    j    place_loop

finalize_test_fit:
    # Prioritize errors
    li   $t0, 3                 # Both errors
    beq  $s2, $t0, return_error_3

    li   $t0, 2                 # Out of bounds
    beq  $s2, $t0, return_error_2

    li   $t0, 1                 # Overlap
    beq  $s2, $t0, return_error_1

    li   $v0, 0                 # Success
    j    test_fit_epilogue

return_error_4:
    li   $v0, 4                 # Invalid type or orientation
    j    test_fit_epilogue

return_error_3:
    li   $v0, 3                 # Both overlap and out-of-bounds errors
    j    test_fit_epilogue

return_error_2:
    li   $v0, 2                 # Out-of-bounds error
    j    test_fit_epilogue

return_error_1:
    li   $v0, 1                 # Overlap error
    j    test_fit_epilogue

test_fit_epilogue:
    # Function Epilogue
    lw   $ra, 12($sp)           # Restore return address
    lw   $s0, 8($sp)            # Restore $s0
    lw   $s1, 4($sp)            # Restore $s1
    lw   $s2, 0($sp)            # Restore $s2
    addi $sp, $sp, 16           # Deallocate stack space
    jr   $ra                    # Return to caller



.include "skeleton.asm"


