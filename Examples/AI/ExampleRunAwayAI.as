/**
 * Example of an AI controlled by a compound capability that runs away from the player.
 */
class AExampleRunAwayAI : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

	// Add the AI's compound behavior as a default capability
	default CapabilityComponent.DefaultCapabilities.Add(n"ExampleRunAwayAICompoundCapability");
};

/**
 * Compound capabilities can contain multiple child capabilities organized through compound nodes.
 * When the compound capability is active, all the child nodes and capabilities in it are evaluated.
 */
class UExampleRunAwayAICompoundCapability : UHazeCompoundCapability
{
	// AI Should be networked.
	// All child capabilities need to indicate network support in their CompoundNetworkSupport default.
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// AI behavior should always be active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	// GenerateBehavior specifies what the behavior tree inside this capability looks like
	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return 
			UHazeCompoundSelector() // Selectors try each child every frame until it finds an active one
			.Try( // Stun
				n"ExampleAIStunnedBehavior" // Handle when the AI is stunned by the player
			)
			.Try( // Run Away
				UHazeCompoundSequence() // Sequences execute each child one by one until it finishes
				.Then( n"ExampleAIStartleBehavior" ) // First play a startle animation to indicate the player was spotted
				.Then( n"ExampleAIRunAwayFromPlayerBehavior" ) // Run away and keep running away until out of range
			)
			.Try( // Idle behavior for the selector to fall back to
				n"ExampleAIIdleBehavior"
			)
		;
	}
};