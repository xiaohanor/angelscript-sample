class UTundraFishieEatPlayerBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UTundraFishieComponent FishieComp;
	UTundraFishieMouthComp MouthComp;
	UBasicAICharacterMovementComponent MoveComp;
	UTundraFishieSettings Settings;
	bool bHasEaten;
	AHazePlayerCharacter Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FishieComp = UTundraFishieComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		MouthComp = UTundraFishieMouthComp::Get(Owner);
		Settings = UTundraFishieSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!FishieComp.CanHunt())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.HasVisibleTarget(TargetOffset = TargetComp.Target.ActorUpVector * Settings.VisibilityTargetOffset) && Time::GetGameTimeSince(FishieComp.LastChaseTime) > 0.5)
			return false;
		if (!TargetComp.Target.ActorCenterLocation.IsWithinDist(MouthComp.WorldLocation, Settings.EatPlayerRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!FishieComp.CanHunt())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (ActiveDuration > Settings.EatPlayerDuration)
			return true;
		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(TundraFishieAnimTags::Attack, EBasicBehaviourPriority::Medium, this);
		bHasEaten = false;
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		FishieComp.DoneEatingTime = Time::GameTimeSeconds + Settings.EatPlayerDuration + Settings.PostEatPlayerResumeSwimAnimDuration;
		FishieComp.bAgitated.Apply(true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		FishieComp.bAgitated.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ShouldEat())
			CrumbEat(Target);

		if (!bHasEaten)
		{
			// Lunge!
			DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + (Target.ActorCenterLocation - Owner.ActorLocation) * 10.0, Settings.EatPlayerMoveSpeed);
			DestinationComp.RotateTowards(Target);
		}
		else
		{
			// Return to normal movement path while maintaining heading
			DestinationComp.MoveTowardsIgnorePathfinding(FishieComp.LastMoveLocation, Settings.EatPlayerReturnMoveSpeed);
			DestinationComp.RotateInDirection(FishieComp.Direction);
		}
	}

	bool ShouldEat()
	{
		if (bHasEaten)
			return false;
		
		if (!Target.HasControl())
			return false;

		const float EatRange = Settings.EatPlayerRange * (0.25 + 0.75 * (ActiveDuration / Settings.EatPlayerDuration));
		if (TargetComp.Target.ActorCenterLocation.IsWithinDist(MouthComp.WorldLocation, EatRange))
			return true;

		// Have we passed target?
		FVector FromStart = Owner.ActorLocation - FishieComp.LastMoveLocation;
		if (FromStart.DotProduct(Target.ActorCenterLocation - Owner.ActorLocation) < 0.0)
			return true;

		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbEat(AHazePlayerCharacter Player)
	{
		Player.KillPlayer(DeathEffect = FishieComp.FishEatDeathEffect);
		bHasEaten = true;
		FishieComp.DoneEatingTime = Time::GameTimeSeconds + Settings.PostEatPlayerResumeSwimAnimDuration;

		UAITundraFishieEventHandler::Trigger_OnBite(Owner);
	}
}
