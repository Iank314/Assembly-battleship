# hw5.asm
# MIPS Assembly Project: Board Game Implementation
# Author: Ian Kaufman
# Date: 12/8/2024

# -----------------------------------
# Data Segment
# -----------------------------------
.data
    space: .asciiz " "                 # Space character for printing between numbers
    newline: .asciiz "\n"              # Newline character
    extra_newline: .asciiz "\n\n"      # Extra newline at end

    # Define board dimensions
    board_width: .word 10               # Number of columns
    board_height: .word 10              # Number of rows

    # Define the board as a 10x10 grid initialized to 0 (empty)
    board: .space 100                    # 10 rows * 10 columns = 100 bytes

    # Mapping from ship_num to display character (optional, not used in printBoard)
    ship_chars: .byte '.', 'A', 'B', 'C', 'D', 'E'

    # Additional data if needed for pieces (optional)
    # Define piece structs or other necessary data here

# -----------------------------------
# Text Segment
# -----------------------------------
.text
.globl zeroOut 
.globl place_tile 
.globl printBoard 
.globl placePieceOnBoard 
.globl test_fit 
.globl main

# -----------------------------------
# Function: zeroOut
# Arguments: None
# Returns: void
# Description: Initializes the board array to 0 (empty)
# -----------------------------------
zeroOut:
    # Function prologue
    addi $sp, $sp, -8          # Allocate stack space for $ra and $s0
    sw $ra, 4($sp)             # Save return address
    sw $s0, 0($sp)             # Save $s0

    # Initialize $s0 to point to the start of the board
    la $s0, board              # $s0 = address of board
    li $t0, 0                  # Initialize loop counter to 0
    li $t1, 100                # Total number of cells (10x10)

zeroOut_loop:
    beq $t0, $t1, zeroOut_done # If counter == 100, done
    sb $zero, 0($s0)            # Set board[counter] = 0
    addi $s0, $s0, 1            # Move to next byte
    addi $t0, $t0, 1            # Increment counter
    j zeroOut_loop

zeroOut_done:
    # Function epilogue
    lw $ra, 4($sp)              # Restore return address
    lw $s0, 0($sp)              # Restore $s0
    addi $sp, $sp, 8            # Deallocate stack space
    jr $ra                      # Return to caller

# -----------------------------------
# Function: place_tile
# Arguments: 
#   $a0 - row
#   $a1 - col
#   $a2 - value (ship_num)
# Returns:
#   $v0 - 0 if successful, 1 if occupied, 2 if out of bounds
# Description: Places a ship tile on the board
# -----------------------------------
place_tile:
    # Function prologue
    addi $sp, $sp, -8          # Allocate stack space
    sw $ra, 4($sp)             # Save return address
    sw $s0, 0($sp)             # Save $s0

    # Load board dimensions
    lw $t6, board_height       # $t6 = board_height
    lw $t7, board_width        # $t7 = board_width

    # Check if row is out of bounds
    blt $a0, $zero, out_of_bounds
    bge $a0, $t6, out_of_bounds

    # Check if col is out of bounds
    blt $a1, $zero, out_of_bounds
    bge $a1, $t7, out_of_bounds

    # Calculate index = row * board_width + col
    mul $t0, $a0, $t7          # $t0 = row * board_width
    add $t0, $t0, $a1          # $t0 = row * board_width + col

    # Load current value from board
    la $s0, board              # $s0 = address of board
    add $s0, $s0, $t0          # $s0 = &board[index]
    lb $t1, 0($s0)             # $t1 = board[index]

    # Check if cell is occupied
    bne $t1, $zero, occupied

    # Set cell to ship_num
    sb $a2, 0($s0)             # board[index] = ship_num

    # Set return value to 0 (success)
    li $v0, 0
    j place_tile_done

occupied:
    # Set return value to 1 (occupied)
    li $v0, 1
    j place_tile_done

out_of_bounds:
    # Set return value to 2 (out of bounds)
    li $v0, 2

place_tile_done:
    # Function epilogue
    lw $ra, 4($sp)              # Restore return address
    lw $s0, 0($sp)              # Restore $s0
    addi $sp, $sp, 8            # Deallocate stack space
    jr $ra                      # Return to caller

# -----------------------------------
# Function: printBoard
# Arguments: None (uses global variables)
# Returns: void
# Description: Prints the current state of the board
# -----------------------------------
printBoard:
    # Function prologue
    addi $sp, $sp, -4          # Allocate stack space for $ra
    sw $ra, 0($sp)             # Save return address

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
    lw $ra, 0($sp)              # Restore return address
    addi $sp, $sp, 4            # Deallocate stack space
    jr $ra                      # Return to caller

# -----------------------------------
# Function: placePieceOnBoard
# Arguments: 
#   $a0 - address of piece struct
#   $a1 - ship_num
# Returns: void
# Description: Places a piece on the board based on its type and orientation
# -----------------------------------
placePieceOnBoard:
    # Function prologue
    addi $sp, $sp, -4          # Allocate stack space for $ra
    sw $ra, 0($sp)             # Save return address

    # Assume $s3 contains the piece type (1-7)

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

piece_square:
    # Code from skeleton.asm's piece_square
    # All orientations are the same for square
    move $a0, $s5          # row
    move $a1, $s6          # col
    move $a2, $s1          # ship_num
    jal place_tile
    or $s2, $s2, $v0       # accumulate error

    move $a0, $s5
    addi $a0, $a0, 1       # row + 1
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5          # row
    move $a1, $s6
    addi $a1, $a1, 1       # col + 1
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    addi $a0, $a0, 1       # row + 1
    move $a1, $s6
    addi $a1, $a1, 1       # col + 1
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0
    j piece_done

# The following piece type functions are included from skeleton.asm
# Ensure that the labels do not conflict with existing labels

piece_line:
    li $t0, 1
    beq $s4, $t0, line_vertical
    li $t0, 3
    beq $s4, $t0, line_vertical
    j line_horizontal

line_vertical:
    move $a0, $s5          # row
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0       # accumulate error

    move $a0, $s5
    addi $a0, $a0, 1
    move $a1, $s6
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    addi $a0, $a0, 2
    move $a1, $s6
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    addi $a0, $a0, 3
    move $a1, $s6
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0
    j piece_done

line_horizontal:
    move $a0, $s5          # row
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    move $a1, $s6
    addi $a1, $a1, 1
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    move $a1, $s6
    addi $a1, $a1, 2
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    move $a1, $s6
    addi $a1, $a1, 3
    move $a2, $s1
    jal place_tile
    j piece_done

# only piece_square and piece_line are fully implemented here

# -----------------------------------
# Function: test_fit
# Arguments: 
#   $a0 - address of piece array (5 pieces)
# Returns: void
# Description: Tests if a piece can fit on the board
# -----------------------------------
test_fit:
    # Function prologue
    addi $sp, $sp, -4          # Allocate stack space for $ra
    sw $ra, 0($sp)             # Save return address

    # Implementation of test_fit goes here
    # Placeholder: Currently does nothing

    # Function epilogue
    lw $ra, 0($sp)              # Restore return address
    addi $sp, $sp, 4            # Deallocate stack space
    jr $ra                      # Return to caller

# -----------------------------------
# Function: main
# Arguments: None
# Returns: void
# Description: Main entry point of the program
# -----------------------------------
main:
    # Function prologue (optional)

    # Initialize the board
    jal zeroOut

    # Example: Place ship_num 1 at row 2, col 3
    li $a0, 2                  # row
    li $a1, 3                  # col
    li $a2, 1                  # ship_num
    jal place_tile
    # Optionally, check $v0 for success

    # Example: Place ship_num 2 at row 5, col 5
    li $a0, 5                  # row
    li $a1, 5                  # col
    li $a2, 2                  # ship_num
    jal place_tile
    # Optionally, check $v0 for success

    # Print the board
    jal printBoard

    # Exit program
    li $v0, 10
    syscall

# -----------------------------------
# Include Skeleton.asm
# -----------------------------------
# The content from skeleton.asm is included here
# Make sure to place all labels and functions appropriately

# Register Usage:
#   Input Registers to this code block (never updated):
#   $s1 - ship_num (piece identifier 1-5)
#   $s4 - piece orientation (1-4)
#   $s5 - piece row location
#   $s6 - piece column location
#
#   Used/Clobbered Registers in this code block:
#   $s2 - accumulated error value
#   $a0 - argument: row position for place_tile
#   $a1 - argument: column position for place_tile
#   $a2 - argument: ship_num for place_tile
#   $v0 - return value from place_tile
#   $t0 - temporary comparisons

# Piece placement cases
piece_square:
    # All orientations are the same for square
    move $a0, $s5          # row
    move $a1, $s6          # col
    move $a2, $s1          # ship_num
    jal place_tile
    or $s2, $s2, $v0       # accumulate error

    move $a0, $s5
    addi $a0, $a0, 1       # row + 1
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5          # row
    move $a1, $s6
    addi $a1, $a1, 1       # col + 1
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    addi $a0, $a0, 1       # row + 1
    move $a1, $s6
    addi $a1, $a1, 1       # col + 1
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0
    j piece_done

piece_line:
    li $t0, 1
    beq $s4, $t0, line_vertical
    li $t0, 3
    beq $s4, $t0, line_vertical
    j line_horizontal

line_vertical:
    move $a0, $s5          # row
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    addi $a0, $a0, 1
    move $a1, $s6
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    addi $a0, $a0, 2
    move $a1, $s6
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    addi $a0, $a0, 3
    move $a1, $s6
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0
    j piece_done

line_horizontal:
    move $a0, $s5          # row
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    move $a1, $s6
    addi $a1, $a1, 1
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    move $a1, $s6
    addi $a1, $a1, 2
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    move $a1, $s6
    addi $a1, $a1, 3
    move $a2, $s1
    jal place_tile
    j piece_done


piece_L:
    li $t0, 1
    beq $s4, $t0, L_orientation1
    li $t0, 2
    beq $s4, $t0, L_orientation2
    li $t0, 3
    beq $s4, $t0, L_orientation3
    j L_orientation4

L_orientation1:
    move $a0, $s5          # row
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    addi $a0, $a0, 1       # row + 1
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    addi $a0, $a0, 2       # row + 2
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5
    addi $a0, $a0, 2       # row + 2
    move $a1, $s6
    addi $a1, $a1, 1       # col + 1
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0
    j piece_done

# Implement L_orientation2, L_orientation3, L_orientation4 similarly

piece_z:
    li $t0, 1
    beq $s4, $t0, z_flat
    li $t0, 3
    beq $s4, $t0, z_flat
    j z_vertical

z_flat:
    move $a0, $s5          # row
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5          # row
    move $a1, $s6
    addi $a1, $a1, 1       # col + 1
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5          # row
    addi $a0, $a0, 1       # row + 1
    move $a1, $s6
    addi $a1, $a1, 1       # col + 1
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5          # row
    addi $a0, $a0, 1       # row + 1
    move $a1, $s6
    addi $a1, $a1, 2       # col + 2
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0
    j piece_done

z_vertical:
    move $a0, $s5          # row
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5          # row
    addi $a0, $a0, 1       # row + 1
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5          # row
    addi $a0, $a0, -1      # row - 1
    move $a1, $s6
    addi $a1, $a1, 1       # col + 1
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0

    move $a0, $s5          # row
    addi $a0, $a0, 1       # row + 1
    move $a1, $s6          # col
    move $a2, $s1
    jal place_tile
    or $s2, $s2, $v0
    j piece_done

# Implement other piece types (reverse_L, T, reverse_z) similarly

# -----------------------------------
# Function: piece_done
# Description: Label to finalize piece placement
# -----------------------------------
piece_done:
    jr $ra

# -----------------------------------
# Function: test_fit
# Arguments: 
#   $a0 - address of piece array (5 pieces)
# Returns: void
# Description: Tests if a piece can fit on the board
# -----------------------------------
test_fit:
    # Function prologue
    addi $sp, $sp, -4          # Allocate stack space for $ra
    sw $ra, 0($sp)             # Save return address

    # Implementation of test_fit goes here

    # Function epilogue
    lw $ra, 0($sp)              # Restore return address
    addi $sp, $sp, 4            # Deallocate stack space
    jr $ra                      # Return to caller

# -----------------------------------
# Function: T_orientation4
# Description: Placeholder for T orientation 4
# -----------------------------------
T_orientation4:
    # Study the other T orientations in skeleton.asm to understand how to write this label/subroutine
    j piece_done

# -----------------------------------
# End of hw5.asm
# -----------------------------------
