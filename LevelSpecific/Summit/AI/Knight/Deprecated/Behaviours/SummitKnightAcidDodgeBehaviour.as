
class USummitKnightAcidDodgeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default CapabilityTags.Add(SummitKnightTags::SummitKnightShield);

	USummitKnightShieldComponent ShieldComp;
	USummitKnightDeprecatedSettings KnightSettings;

	AHazeActor Instigator;
	float bAcidHitTime = 0;
	bool bDodging = true;
	bool bStrafeLeft = false;
	float Radius;
	float AcidDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShieldComp = USummitKnightShieldComponent::GetOrCreate(Owner);
		KnightSettings = USummitKnightDeprecatedSettings::GetSettings(Owner);
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;

		auto AcidResponseComp = UAcidResponseComponent::GetOrCreate(Owner);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if(Time::GetGameTimeSince(bAcidHitTime) > KnightSettings.AcidDodgeResetDuration)
			AcidDuration = 0;
		bAcidHitTime = Time::GetGameTimeSeconds();
		Instigator = Hit.PlayerInstigator;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(Instigator == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(bDodging && Time::GetGameTimeSince(bAcidHitTime) > KnightSettings.AcidDodgeRecoveryDuration)
			return true;
		if(!bDodging && Time::GetGameTimeSince(bAcidHitTime) > KnightSettings.AcidDodgeInterruptDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bStrafeLeft = Math::RandBool();
		bDodging = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Instigator = nullptr;

		// if(Owner.IsCapabilityTagBlocked(SummitKnightTags::SummitKnightShieldBlocking))
		// 	AnimComp.RequestFeature(FeatureTagSummitRubyKnight::Shield, SubTagSummitRubyKnightShield::ShieldAcid, EBasicBehaviourPriority::High, Owner);

		ShieldComp.OnAcidDodgeCompleted.Broadcast();

		// Anti-cheese to prevent trying to spray in multiple bursts
		AcidDuration += KnightSettings.AcidDodgeActivationDuration / 2;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AcidDuration += DeltaTime;
		if(AcidDuration < KnightSettings.AcidDodgeActivationDuration)
			return;

		//AnimComp.RequestFeature(FeatureTagSummitRubyKnight::Shield, SubTagSummitRubyKnightShield::ShieldDodge, EBasicBehaviourPriority::High, this);
		bDodging = true;
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = Instigator.ActorLocation;
		FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc);
		Side = Side.GetClampedToSize(DestinationComp.MinMoveDistance, DestinationComp.MinMoveDistance + 80.0);
		if (bStrafeLeft)
			Side *= -1.0;
		float CircleDist = OwnLoc.Distance(TargetLoc);
		FVector CircleOffset = (OwnLoc + Side - TargetLoc).GetClampedToMaxSize(CircleDist);
		FVector StrafeDest = TargetLoc + CircleOffset;
		DestinationComp.MoveTowards(StrafeDest, KnightSettings.AcidDodgeMoveSpeed);

		DestinationComp.RotateTowards(Instigator);
		
		if (DoChangeDirection(StrafeDest))
		{
			bStrafeLeft = !bStrafeLeft;
		}
	}
	
	private bool DoChangeDirection(FVector StrafeDest)
	{
		if(DestinationComp.MoveFailed())
			return true;

		FVector StrafeDestNavMesh;
		FVector PathStrafeDest = StrafeDest + (StrafeDest - Owner.ActorLocation).GetSafeNormal() * Radius;
		if(!Pathfinding::FindNavmeshLocation(PathStrafeDest, 0.0, 100.0, StrafeDestNavMesh))
			return true;

		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, StrafeDestNavMesh))
			return true;

		return false;
	}
}