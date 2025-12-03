struct FGnapeFleeParams
{
	float ReactTime;
	float FleeTime;
	float LeapTime;
	float LeapSpeed;
	float LeapHeightFactor;
}

class UTundraGnapeFleeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	AHazePlayerCharacter Monkey;
	UTundraGnatSettings Settings;
	UTundraGnatComponent GnapeComp;
	UBasicAIHealthComponent HealthComp;
	ATundraWalkingStick WalkingStick;
	float FleeOffset;
	FGnapeFleeParams FleeParams;
	bool bReacted = false;
	bool bFleeing = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GnapeComp = UTundraGnatComponent::Get(Owner); 
		Monkey = Game::Mio;
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = UTundraGnatSettings::GetSettings(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		GnapeComp.bFleeingLeap = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if ((WalkingStick == nullptr) && (GnapeComp.Host != nullptr))
			WalkingStick = Cast<ATundraWalkingStick>(GnapeComp.Host);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGnapeFleeParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (WalkingStick == nullptr)
			return false;
		if (!WalkingStick.bMakeAIsFlee)
			return false; 
		OutParams.ReactTime = Math::RandRange(0.0, 0.7);
		OutParams.FleeTime = OutParams.ReactTime + Math::RandRange(0.5, 1.0);
		OutParams.LeapTime = OutParams.FleeTime + Math::RandRange(3.0, 7.0);
		OutParams.LeapSpeed = Math::RandRange(1500.0, 2000.0);
		OutParams.LeapHeightFactor = Math::RandRange(0.1, 0.3);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > 10.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGnapeFleeParams Params)
	{
		Super::OnActivated();

		// Prepare to run away!
		FleeOffset = Math::RandRange(-1000.0, 1000.0);
		bFleeing = false;
		bReacted = false;
		FleeParams = Params;

		UTundraGnatSettings::SetTurnDuration(Owner, 0.7, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, WalkingStick);
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (GnapeComp.bFleeingLeap)
			return;

		if (ActiveDuration < FleeParams.FleeTime)
		{
			// Freeze in place in preparation of running
			DestinationComp.RotateTowards((Game::Zoe.ActorLocation + Game::Mio.ActorLocation) * 0.5);	
			if (!bReacted && ActiveDuration > FleeParams.ReactTime)
			{
				bReacted = true;
				AnimComp.RequestFeature(TundraGnatTags::TargetedByMonkeyThrow, EBasicBehaviourPriority::Medium, this);
			}
			return; 
		}

		// Run Forrest! Run!
		if (!bFleeing)
			AnimComp.ClearFeature(this); 
		bFleeing = true;

		FVector OwnLoc = Owner.ActorLocation;	
		FVector AvoidLoc = GetAvoidLocation();
		FVector AwayDir = (OwnLoc - AvoidLoc).GetSafeNormal2D();
		DestinationComp.MoveTowardsIgnorePathfinding(OwnLoc + AwayDir * 1000.0, Settings.FleeSpeed);

		if (ShouldLeapAway(AvoidLoc))
		{
			GnapeComp.bFleeingLeap = true;
			GnapeComp.FleeingLeapImpulse = (AwayDir + FVector(0.0, 0.0, FleeParams.LeapHeightFactor)) * FleeParams.LeapSpeed;
			AnimComp.RequestFeature(TundraGnatTags::Leaping, EBasicBehaviourPriority::Medium, this);
		}
	}

	FVector GetAvoidLocation()
	{
		USceneComponent Body = GnapeComp.HostBody;
		if (Body != nullptr)
			return Math::ProjectPositionOnInfiniteLine(Body.WorldLocation, Body.ForwardVector, Owner.ActorLocation + Body.ForwardVector * FleeOffset);		
		return Game::Zoe.ActorLocation;
	}

	bool ShouldLeapAway(FVector AvoidLoc) const
	{
		if (ActiveDuration > FleeParams.LeapTime)
			return true;

		USceneComponent Body = GnapeComp.HostBody;
		if (Body != nullptr)
		{
			// Far enough from host center line?
			FVector HostCenterLoc = Math::ProjectPositionOnInfiniteLine(Body.WorldLocation, Body.ForwardVector, Owner.ActorLocation);
			if (!Owner.ActorLocation.IsWithinDist2D(HostCenterLoc, 1300.0))
			{
				// Need to be facing away from danger
				if (Owner.ActorForwardVector.DotProduct((Owner.ActorLocation - AvoidLoc).GetSafeNormal2D()) > 0.866)
					return true;		
			}
		}

		return false;
	}


}


