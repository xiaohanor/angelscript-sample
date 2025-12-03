class UBasicAITraversalSettings : UHazeComposableSettings
{
	// Seconds when launching before accelerating to max speed. Higher values means smoother start but slower traversal.
	UPROPERTY(Category = "Traversal")
	float LaunchDuration = 0.5;

	UPROPERTY(Category = "Traversal")
	float TurnDuration = 3.0;

	UPROPERTY(Category = "Traversal|Chase")
	float ChaseSpeed = 2500.0; 

	UPROPERTY(Category = "Traversal|Chase")
	float ChaseMinRange = 2000.0;

	UPROPERTY(Category = "Traversal|Evade")
	float EvadeRange = 500.0; 

	// How often we check if we want to do a traversal evade. Low values here might be annoying, as the AI will jump away a lot.
	UPROPERTY(Category = "Traversal|Evade")
	float EvadeCheckInterval = 5.0; 

	UPROPERTY(Category = "Traversal|Evade")
	float EvadeSpeed = 2500.0; 

	UPROPERTY(Category = "Traversal|Entrance")
	float EvadeDestinationMaxRange = 4000.0;

	UPROPERTY(Category = "Traversal|Entrance")
	float EvadeDestinationMinRange = 300.0;

	UPROPERTY(Category = "Traversal|Entrance")
	float EntranceSpeed = 2500.0; 

	UPROPERTY(Category = "Traversal|Entrance")
	float EntranceMaxRange = 5000.0;

	UPROPERTY(Category = "Traversal|Entrance")
	float EntranceMinRange = 400.0;
}
