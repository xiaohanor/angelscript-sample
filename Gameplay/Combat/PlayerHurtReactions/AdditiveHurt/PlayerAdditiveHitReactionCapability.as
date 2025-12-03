struct FPlayerAdditiveHitReactionParams
{
	EPlayerAdditiveHitReactionType Type;	
	EHazeCardinalDirection Direction;
}

class UPlayerAdditiveHitReactionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"HitReaction");
	default CapabilityTags.Add(n"AdditiveHitReaction");
	default CapabilityTags.Add(n"BlockedByCutscene");

	default DebugCategory = n"Hitreaction";

	default TickGroup = EHazeTickGroup::LastMovement;

	UPlayerAdditiveHitReactionComponent HitReactionComp;
	float RepeatCooldown;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HitReactionComp = UPlayerAdditiveHitReactionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerAdditiveHitReactionParams& OutParams) const
	{
		if (HitReactionComp.HitType == EPlayerAdditiveHitReactionType::None)
			return false;
		if (HitReactionComp.HitFrame < GFrameNumber-1)
			return false;
		OutParams.Direction = HitReactionComp.HitDirection;
		OutParams.Type = HitReactionComp.HitType;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Ignore any other additive hurts for a short while
		if (ActiveDuration > RepeatCooldown)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerAdditiveHitReactionParams Params)
	{
		HitReactionComp.HitType = Params.Type;
		HitReactionComp.HitDirection = Params.Direction;

		if (Player.Mesh.CanRequestAdditiveFeature())
			Player.Mesh.RequestAdditiveFeature(n"HitReaction_Addative", this);		

		// Expose this if necessary
		RepeatCooldown = Math::RandRange(0.1, 0.4);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Consume hit reaction, including any hurts during ongoing hurt 
		HitReactionComp.HitType = EPlayerAdditiveHitReactionType::None;
	}
};