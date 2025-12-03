// Capability Request Example
// See http://wiki.hazelight.se/Scripting/Capabilities
// (Control+Click) on links to open

/**
 * This is an example structure of how you would add a capability to the player
 * when a specific actor is placed in the level.
 */


/**
 * Actor placed in the level representing a bouncepad.
 */
class AExample_BouncePad : AHazeActor
{
	// We can use the player request component to ensure a specific capability is on the player.
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"UExample_BouncePadCapability");

	UPROPERTY()
	FVector Impulse(0.0, 0.0, 1000.0);

	void OnPlayerLandOnBouncePad(AHazePlayerCharacter Player)
	{
		auto BounceComp = UExample_BouncePadComponent::Get(Player);
		BounceComp.ActiveBouncePad = this;
	}

	void OnPlayerLeaveBouncePad(AHazePlayerCharacter Player)
	{
		auto BounceComp = UExample_BouncePadComponent::Get(Player);
		BounceComp.ActiveBouncePad = nullptr;
	}
};

/**
 * Component on the player tracking which bouncepad we are standing on.
 */
class UExample_BouncePadComponent : UActorComponent
{
	AExample_BouncePad ActiveBouncePad;
};

/**
 * Struct containing parameters used when the bouncepad capability activates.
 * The values in this struct are synced over network.
 */
struct FBouncePadActivationParams
{
	AExample_BouncePad BouncePad;
};

/**
 * Capability that is added to the player by the bouncepad.
 */
class UExample_BouncePadCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 10;

	UExample_BouncePadComponent BounceComp;
	AExample_BouncePad BouncePad;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BounceComp = UExample_BouncePadComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBouncePadActivationParams& ActivationParams) const
	{
		if (BounceComp.ActiveBouncePad != nullptr)
		{
			ActivationParams.BouncePad = BounceComp.ActiveBouncePad;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBouncePadActivationParams ActivationParams)
	{
		BouncePad = ActivationParams.BouncePad;
		BounceComp.ActiveBouncePad = nullptr;

		//Player.AddImpulse(BouncePad.Impulse);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}
};
