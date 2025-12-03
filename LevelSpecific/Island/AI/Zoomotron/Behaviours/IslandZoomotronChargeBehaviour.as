class UIslandZoomotronChargeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	FVector StartLocation;
	FVector Destination;
	bool bTrackTarget;
	bool bWasHeadingTowardsDestination;
	bool bWasCharging;
	float TelegraphEndTime;
	AHazePlayerCharacter PlayerTarget;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	UIslandZoomotronSettings ZoomotronSettings;

	TArray<AHazeActor> AvailableTargets;

	FHazeAcceleratedFloat HackYaw; 
	FHazeAcceleratedFloat HackRoll;

	UStaticMeshComponent MeshSpikes;
	FHazeAcceleratedFloat CurrentScale;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ZoomotronSettings = UIslandZoomotronSettings::GetSettings(Owner);
		AAIIslandZoomotron OwnerZoomotron = Cast<AAIIslandZoomotron>(Owner);
		MeshSpikes = OwnerZoomotron.MeshSpikes;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && !IsBlocked() && WantsToAttack())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);

		// HACK: Spin mesh offset as temp anim
		// UMeshComponent Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		// FRotator MeshRot = Mesh.RelativeRotation;
		// if (IsActive())
		// {
		// 	if (Time::GameTimeSeconds < TelegraphEndTime)
		// 	{
		// 		float SpinDegrees = 360.0 * 1.0 * Math::CeilToFloat(ZoomotronSettings.ChargeTelegraphDuration + 3.0);
		// 		Mesh.SetRelativeRotation(FRotator(MeshRot.Pitch, HackYaw.AccelerateTo(SpinDegrees, ZoomotronSettings.ChargeTelegraphDuration, DeltaTime), MeshRot.Roll));
		// 	}
		// 	else
		// 	{
		// 		HackYaw.Value = FRotator::NormalizeAxis(HackYaw.Value);
		// 		float Yaw = HackYaw.AccelerateTo(0.0, 1.0, DeltaTime);
		// 		float Roll = HackRoll.AccelerateTo(360.0 * 8.0, 3.0, DeltaTime);
		// 		Mesh.SetRelativeRotation(FRotator(MeshRot.Pitch, Yaw, Roll));
		// 	}
		// }
		// else
		// {
		// 		HackYaw.Value = FRotator::NormalizeAxis(HackYaw.Value);
		// 		float Yaw = HackYaw.AccelerateTo(0.0, 1.0, DeltaTime);
		// 		HackRoll.Value = FRotator::NormalizeAxis(HackRoll.Value);
		// 		float Roll = HackRoll.AccelerateTo(0.0, 1.0, DeltaTime);
		// 		Mesh.SetRelativeRotation(FRotator(MeshRot.Pitch, Yaw, Roll));
		// }
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.ChargeRange))
			return false;

		// Only attack when we're facing target
		FVector ToTarget = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation);
		ToTarget.Z = 0.0;
		if (Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal()) < 0.707) 
			return false;

		// Only start charge against players when in front and in camera direction
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Player != nullptr)
		{
			FVector ViewYawDir = FRotator(0.0, Player.ViewRotation.Yaw, 0.0).Vector();
			if (ViewYawDir.DotProduct(-ToTarget) < 0.707)
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (ZoomotronSettings.ChargeGentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(ZoomotronSettings.ChargeGentlemanCost))
			return false;
		if (!WantsToAttack())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, ZoomotronSettings.ChargeGentlemanCost);

		// Telegraph for a while, then charge in
		TelegraphEndTime = Time::GameTimeSeconds + ZoomotronSettings.ChargeTelegraphDuration;
		bWasCharging = false;
		AnimComp.RequestFeature(LocomotionFeatureAITags::Taunt, SubTagAITaunts::Telegraph, EBasicBehaviourPriority::Medium, this);
		bTrackTarget = true;
		bWasHeadingTowardsDestination = false;
		//UIslandZoomotronEffectHandler::Trigger_OnTelegraphCharge(Owner);

		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);

		// We can only hit our designated target
		AvailableTargets.Empty(1);
		AvailableTargets.Add(TargetComp.Target);

		UMeshComponent Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		HackYaw.SnapTo(Mesh.RelativeRotation.Yaw);
		HackRoll.SnapTo(Mesh.RelativeRotation.Roll);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, ZoomotronSettings.ChargeTokenCooldown);
		UIslandZoomotronEffectHandler::Trigger_OnChargeEnd(Owner);
		CurrentScale.SnapTo(0);
		MeshSpikes.SetWorldScale3D(FVector(0));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds < TelegraphEndTime)
		{
			TelegraphCharge();
			CurrentScale.SpringTo(0.8, 150, 0.5, DeltaTime);
			MeshSpikes.SetWorldScale3D(FVector(CurrentScale.Value));
		}
		else
			PerformCharge();
	}

	void StartCharge()
	{
		AnimComp.RequestFeature(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::ChargeAttack, EBasicBehaviourPriority::Medium, this);
		StartLocation = Owner.ActorLocation;
		Destination = TargetComp.Target.ActorTransform.TransformPosition(BasicSettings.ChargeOffset);
		UIslandZoomotronEffectHandler::Trigger_OnChargeStart(Owner);
		bWasCharging = true;
	}

	void TelegraphCharge()
	{
		// Move in front of target predicted location before starting attack run
		FVector PredictedTargetLoc = TargetComp.Target.ActorLocation + TargetComp.Target.ActorVelocity * 0.5;
		FVector OffsetDir = TargetComp.Target.ActorForwardVector;
		if (PlayerTarget != nullptr)
			OffsetDir = PlayerTarget.ViewRotation.Vector().GetSafeNormal2D();
		FVector TelegraphDestination = PredictedTargetLoc + OffsetDir * BasicSettings.ChargeRange;
		TelegraphDestination.Z = PredictedTargetLoc.Z + ZoomotronSettings.ChargeTelegraphHeight;

		float Speed = BasicSettings.ChargeMoveSpeed;
		float Threshold = BasicSettings.ChargeMoveSpeed * 0.2;
		if (TelegraphDestination.IsWithinDist(Owner.ActorLocation, Threshold))
			Speed *= (TelegraphDestination.Distance(Owner.ActorLocation) / Threshold); 
		DestinationComp.MoveTowards(TelegraphDestination, Speed);
		DestinationComp.RotateTowards(TargetComp.Target);
	}

	void PerformCharge()
	{
		if (!bWasCharging)
			StartCharge();

		// Stay in charge anim (when we stop requesting it we will play end anim)
		AnimComp.RequestFeature(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::ChargeAttack, EBasicBehaviourPriority::Medium, this);

		FVector OwnLoc = Owner.ActorLocation;
		if (bTrackTarget)
		{
			// Update destination
			Destination = TargetComp.Target.ActorTransform.TransformPosition(BasicSettings.ChargeOffset);

			// Should we stop following target?
			if (OwnLoc.IsWithinDist(Destination, BasicSettings.ChargeTrackTargetRange))
				bTrackTarget = false;
		}

		// Move beyond destination, so we won't stop when coming close
		FVector ToDestDir = (Destination - OwnLoc).GetSafeNormal();
		FVector BeyondDest = Destination + ToDestDir * (DestinationComp.MinMoveDistance + 80.0);
		DestinationComp.MoveTowards(BeyondDest, BasicSettings.ChargeMoveSpeed);
		DestinationComp.RotateTowards(BeyondDest);

		if (!bWasHeadingTowardsDestination && (ToDestDir.DotProduct(Owner.ActorVelocity) > 0.0))
			bWasHeadingTowardsDestination = true;

		if (ShouldEndCharge())
		{
			// Note that we do this after movement, to preserve velocity
			Cooldown.Set(BasicSettings.ChargeCooldown);
			return;	
		}
	}

	bool ShouldEndCharge()
	{
		// Past max duration?
		if (ActiveDuration > BasicSettings.ChargeMaxDuration)
			return true;

		if (bWasHeadingTowardsDestination)
		{
			// We have been going the right direction, have we passed destination? 
			if (Owner.ActorVelocity.DotProduct(Destination - Owner.ActorLocation) < 0.0)
				return true;
		}

		// Any targets left?
		if (AvailableTargets.Num() == 0)
			return true;

		// Keep charging
		return false;
	}
}

