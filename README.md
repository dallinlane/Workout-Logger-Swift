# Workout Logger
An iOS app designed for users to log exercises and track their fitness progress over time.

This application is a comprehensive workout tracker for iOS, enabling users to record, manage, and analyze their workout routines with advanced functionality to track sets, reps, weights, and performance progression.

## Home Screen
The Home View serves as the main entry point, providing an intuitive interface for creating a workout, loading templates, accessing charts, managing settings, and updating goal exercises.

## Workout Logging Functionality
When creating an exercise, four main controllers support the user journey: BodyPartViewController, ExerciseTableViewController, WorkoutPreviewController, and TrainingViewController.

### BodyPartViewController
This screen organizes body parts (e.g., chest, triceps, quads) into categories. Users can edit category names by tapping an edit button with a pencil icon or delete categories by swiping left. Tapping a category redirects users to the ExerciseTableViewController.

### ExerciseTableViewController
This screen lists exercises related to the selected body part, allowing users to choose exercises for logging. Exercises can be marked as either supersets or ordered sets. Similar to BodyPartViewController, users can rename exercises and toggle options such as weight/bodyweight and increment weight switches.

### WorkoutPreviewController
Here, users specify the number of sets for each exercise and have the option to save their workout as a template.

### TrainingViewController
This is where users perform the exercises. If the increment weight feature is enabled, the weight automatically updates according to the set increment.

## Goals
Three controllers—GoalListTableViewController, EditGoalListTableViewController, and GoalTableViewController—allow users to create and manage daily goals. For instance, if a user has a goal of completing 100 pull-ups daily, they can log their progress here. The EditGoalListTableViewController allows users to rename the goal, adjust the target reps, and select whether the exercise is bodyweight or weighted.

## Charts
The Charts feature lets users visualize their progress over time for any goal or exercise, with adjustable date ranges.

## Additional Features
Users can toggle between light and dark mode in the Settings screen.
