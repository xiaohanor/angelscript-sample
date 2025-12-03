struct FIslandWalkerRepositionBehaviourParams
{
	FName Direction;
}

class UIslandWalkerRepositionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 

	UIslandWalkerSettings Settings;

	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerLegsComponent LegsComp;

	TArray<UIslandWalkerStompComponent> Stomps;

	float Duration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);
		Owner.GetComponentsByClass(Stomps);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		UTargetTrailComponent::GetOrCreate(Game::Mio);
		UTargetTrailComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandWalkerRepositionBehaviourParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if (LegsComp.NumDestroyedLegs() == 0)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!WalkerComp.CanPerformAttack(EISlandWalkerAttackType::Reposition))
			return false;
		
		// Let's walk the walk!
		OutParams.Direction = GetRepositionDirection();
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Duration) 
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandWalkerRepositionBehaviourParams Params)
	{
		Super::OnActivated();
		WalkerComp.LastAttack = EISlandWalkerAttackType::Reposition;
	
		Duration = WalkerAnimComp.GetRequestedAnimation(FeatureTagWalker::Walk, Params.Direction).PlayLength;
		AnimComp.RequestFeature(FeatureTagWalker::Walk, Params.Direction, EBasicBehaviourPriority::Medium, this, Duration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Settings.RepositionCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (UIslandWalkerStompComponent Stomp : Stomps)
		{
			Stomp.UpdateStomp(DeltaTime);
			Stomp.StompPlayers();
		}
	}

	FName GetRepositionDirection() const
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector IdealDir = (TargetComp.Target.ActorLocation - OwnLoc).GetSafeNormal2D();
		FVector Fwd = Owner.ActorForwardVector;
		FVector Right = Owner.ActorRightVector;
		float FwdDot = Fwd.DotProduct(IdealDir);
		float RightDot = Right.DotProduct(IdealDir);
		TArray<FVector> BestDirs;
		BestDirs.SetNum(4);
		if (Math::Abs(FwdDot) > Math::Abs(RightDot))
		{
			BestDirs[0] = (FwdDot > 0.0) ? Fwd : -Fwd;
			BestDirs[1] = (RightDot > 0.0) ? Right : -Right;
		}
		else 
		{
			BestDirs[0] = (RightDot > 0.0) ? Right : -Right;
			BestDirs[1] = (FwdDot > 0.0) ? Fwd : -Fwd;
		}
		BestDirs[2] = -BestDirs[1];
		BestDirs[3] = -BestDirs[0];

		FVector ValidDir = BestDirs[3]; // Fallback
		for (int i = 0; i < 3; i++)
		{
			FVector Dest = OwnLoc + BestDirs[i] * Settings.RepositionMoveLength;
			if (WalkerComp.ArenaLimits.IsWithinInnerEdge(Dest, -800.0, -200.0))
			{
				ValidDir = BestDirs[i];
				break;
			}
		}

		if (ValidDir == Fwd)
			return SubTagWalkerWalk::Forward;
		if (ValidDir == -Right)
			return SubTagWalkerWalk::Left;
		if (ValidDir == Right)
			return SubTagWalkerWalk::Right;
		return SubTagWalkerWalk::Backward;
	}
}