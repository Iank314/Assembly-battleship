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
    # Place the center block
    move $a0, $s5              # $a0 = row (center)
    move $a1, $s6              # $a1 = col (center)
    move $a2, $s1              # $a2 = ship_num
    jal place_tile             # Call place_tile
    or $s2, $s2, $v0           # Accumulate error in $s2

    # Place the top block
    move $a0, $s5              # $a0 = row
    addi $a0, $a0, -1          # $a0 = row - 1 (top)
    move $a1, $s6              # $a1 = col
    move $a2, $s1              # $a2 = ship_num
    jal place_tile             # Call place_tile
    or $s2, $s2, $v0           # Accumulate error in $s2

    # Place the bottom block
    move $a0, $s5              # $a0 = row
    addi $a0, $a0, 1           # $a0 = row + 1 (bottom)
    move $a1, $s6              # $a1 = col
    move $a2, $s1              # $a2 = ship_num
    jal place_tile             # Call place_tile
    or $s2, $s2, $v0           # Accumulate error in $s2

    # Place the left block
    move $a0, $s5              # $a0 = row
    move $a1, $s6              # $a1 = col
    addi $a1, $a1, -1          # $a1 = col - 1 (left)
    move $a2, $s1              # $a2 = ship_num
    jal place_tile             # Call place_tile
    or $s2, $s2, $v0           # Accumulate error in $s2

    # Place the right block (new addition for balance)
    move $a0, $s5              # $a0 = row
    move $a1, $s6              # $a1 = col
    addi $a1, $a1, 1           # $a1 = col + 1 (right)
    move $a2, $s1              # $a2 = ship_num
    jal place_tile             # Call place_tile
    or $s2, $s2, $v0           # Accumulate error in $s2

    # Jump to piece_done after all blocks are placed
    j piece_done




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

    # Initialize accumulated error register
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







test_fit:
    # Function Prologue
    addi $sp, $sp, -16         # Allocate stack space
    sw   $ra, 12($sp)          # Save return address
    sw   $s0, 8($sp)           # Save $s0 (loop counter)
    sw   $s1, 4($sp)           # Save $s1 (ship struct address)
    sw   $s2, 0($sp)           # Save $s2 (total error)

    li   $s0, 0                # Initialize loop counter to 0
    move $s1, $a0              # $s1 points to the start of the array of ships
    li   $s2, 0                # Initialize error to 0

    # Ensure starting address is aligned
    andi $t0, $s1, 3           # Check if $s1 is word-aligned (last 2 bits == 0)
    bne  $t0, $zero, return_error_4  # If not aligned, return error 4

validate_loop:
    # Check if all 5 ships have been processed
    li   $t0, 5                # Constant for number of ships
    beq  $s0, $t0, process_ships  # Exit validation loop when $s0 == 5

    # Load ship type and orientation from the struct
    lw   $t1, 0($s1)           # $t1 = type
    lw   $t2, 4($s1)           # $t2 = orientation

    # Validate type (1 <= type <= 7)
    li   $t3, 1
    blt  $t1, $t3, return_error_4  # If type < 1, return 4
    li   $t3, 7
    bgt  $t1, $t3, return_error_4  # If type > 7, return 4

    # Validate orientation (1 <= orientation <= 4)
    li   $t3, 1
    blt  $t2, $t3, return_error_4  # If orientation < 1, return 4
    li   $t3, 4
    bgt  $t2, $t3, return_error_4  # If orientation > 4, return 4

    # Increment to the next ship struct (4 fields per struct, 16 bytes total)
    addi $s1, $s1, 16
    addi $s0, $s0, 1           # Increment loop counter
    j    validate_loop         # Repeat validation loop

process_ships:
    # Reset loop counter and pointer to the start of the array
    li   $s0, 0
    move $s1, $a0

place_loop:
    # Check if all 5 ships have been processed
    li   $t0, 5                # Constant for number of ships
    beq  $s0, $t0, finalize_test_fit  # Exit loop when $s0 == 5

    # Place the current ship on the board
    move $a0, $s1              # Address of the current ship struct
    addi $a1, $s0, 1           # Ship number is 1-based index
    jal  placePieceOnBoard     # Call placePieceOnBoard
    or   $s2, $s2, $v0         # Accumulate errors

    # Increment to the next ship struct
    addi $s1, $s1, 16          # Move to the next ship struct
    addi $s0, $s0, 1           # Increment loop counter
    j    place_loop            # Repeat placement loop

finalize_test_fit:
    # Check accumulated errors and return appropriate status
    beq  $s2, $zero, return_success  # If no errors, return success

    # Return the highest error priority
    andi $t0, $s2, 1           # Check for occupied error
    bne  $t0, $zero, return_error_1

    andi $t0, $s2, 2           # Check for out-of-bounds error
    bne  $t0, $zero, return_error_2

    li   $v0, 3                # Return mixed error
    j    test_fit_epilogue

return_error_4:
    li   $v0, 4                # Return orientation out-of-bounds error
    j    test_fit_epilogue

return_error_1:
    li   $v0, 1                # Return occupied error
    j    test_fit_epilogue

return_error_2:
    li   $v0, 2                # Return out-of-bounds error
    j    test_fit_epilogue

return_success:
    li   $v0, 0                # Return success

test_fit_epilogue:
    # Function Epilogue
    lw   $ra, 12($sp)          # Restore return address
    lw   $s0, 8($sp)           # Restore $s0
    lw   $s1, 4($sp)           # Restore $s1
    lw   $s2, 0($sp)           # Restore $s2
    addi $sp, $sp, 16          # Deallocate stack space
    jr   $ra                   # Return to caller



.include "skeleton.asm"