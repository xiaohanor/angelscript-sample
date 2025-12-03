struct FSkylineTorHammerStolenAttackCapabilityParams
{
	FAimingResult AimingResult;
	UGravityWhipUserComponent WhipUser;
}

class USkylineTorHammerStolenAttackCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	
	USkylineTorHammerComponent HammerComp;
	UBasicAIHealthBarComponent HealthBarComp;
	USkylineTorHammerStolenComponent StolenComp;
	USkylineTorHammerPivotComponent PivotComp;
	USkylineTorDamageComponent TorDamageComp;
	USkylineTorExposedComponent TorExposedComp;
	ASkylineTor Tor;
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedFloat AccSpeed;
	FAimingResult AimingResults;
	FVector StartLocation;
	int AttackVariation;
	float AttackAlpha;
	float DeactivatedTime;
	bool bNoTargetAttack;
	FVector AimingLocation;
	USceneComponent AutoAimTarget;
	FVector FinalLocation;
	bool bFinishingBlow;
	UGravityWhipUserComponent WhipUser;

	float AttackedTime;
	float RecoveryTime;
	const float HitDuration = 0.15;
	float RecoveryDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);
		StolenComp = USkylineTorHammerStolenComponent::GetOrCreate(Owner);
		PivotComp = USkylineTorHammerPivotComponent::GetOrCreate(Owner);
		Tor = TListedActors<ASkylineTor>().GetSingle();
		TorDamageComp = USkylineTorDamageComponent::Get(Tor);
		TorExposedComp = USkylineTorExposedComponent::GetOrCreate(Tor);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineTorHammerStolenAttackCapabilityParams& Params) const
	{
		if(!StolenComp.bAttack)
			return false;
		if(StolenComp.WhipUserComp == nullptr)
			return false;
		if (TorDamageComp.bIsPerformingFinishingHammerBlow && !SkylineTorDevToggleNamespace::StayExposed.IsEnabled()) // Can only activate once per SkylineTorExposedBehaviour-activation.
			return false;

		UPlayerAimingComponent AimingComp = UPlayerAimingComponent::Get(StolenComp.WhipUserComp.Owner);
		if(AimingComp == nullptr)
			return false;

		FAimingResult Result = AimingComp.GetAimingTarget(n"TorHammerAim");
		Params.AimingResult = Result;
		Params.WhipUser = StolenComp.WhipUserComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(RecoveryTime > SMALL_NUMBER && Time::GetGameTimeSince(RecoveryTime) > RecoveryDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineTorHammerStolenAttackCapabilityParams Params)
	{
		AimingResults = Params.AimingResult;
		WhipUser = Params.WhipUser;

		PivotComp.SetPivot(HammerComp.HoldHammerComp.Hammer.HeadLocation.WorldLocation);
		AccLocation.SnapTo(PivotComp.Pivot.ActorLocation);
		AccRotation.SnapTo(PivotComp.Pivot.ActorRotation);

		AttackAlpha = 0;
		AccSpeed.SnapTo(0);
		StartLocation = PivotComp.Pivot.ActorLocation;

		AttackedTime = 0;
		RecoveryTime = 0;
		StolenComp.bIdle = false;

		AutoAimTarget = AimingResults.AutoAimTarget;
		bNoTargetAttack = AutoAimTarget == nullptr;
		AimingLocation = WhipUser.GrabCenterLocation;

		float BaseDuration = 0.8;
		StolenComp.PlayerStolenComp.AttackDuration = bNoTargetAttack ? BaseDuration : BaseDuration + HitDuration;

		// Is this the finishing blow for this sequence of hammer attacks?
		if ((TorDamageComp.NumConsecutiveHammerHits >= 3 || TorExposedComp.bFinalExpose) && !bNoTargetAttack)
		{
			TorDamageComp.bIsPerformingFinishingHammerBlow = true;
			TorDamageComp.OnFinishingHammerBlowStarted.Broadcast();
			StolenComp.FinalBlowCameraDuration = TorExposedComp.bFinalExpose ? 2 : 1;

			FApplyPointOfInterestSettings PoiSettings;
			FHazePointOfInterestFocusTargetInfo FocusTarget;
			FocusTarget.SetFocusToActor(Tor);		
			StolenComp.PlayerStolenComp.Player.ApplyPointOfInterest(this,FocusTarget,PoiSettings,1,EHazeCameraPriority::Medium);
			StolenComp.PlayerStolenComp.Player.ApplyCameraSettings(Tor.ZoeHammerAttackLastHit,1,this,EHazeCameraPriority::Medium,0);

			bFinishingBlow = true;

			FHazePlaySlotAnimationParams AnimParams;
			AnimParams.Animation = StolenComp.PlayerFinalBlowAnim;
			StolenComp.PlayerStolenComp.Player.PlaySlotAnimation(AnimParams);

			StolenComp.PlayerStolenComp.Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			StolenComp.PlayerStolenComp.Player.BlockCapabilities(PlayerMovementTags::Jump, this);
			StolenComp.PlayerStolenComp.Player.BlockCapabilities(PlayerMovementTags::GroundJump, this);
		}

		RecoveryDuration = TorDamageComp.bIsPerformingFinishingHammerBlow ? StolenComp.PlayerFinalBlowAnim.PlayLength : 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AttackVariation++;
		if(AttackVariation > 2)
			AttackVariation = 0;
		StolenComp.bIdle = true;

		if(bFinishingBlow)
		{
			TorDamageComp.bIsPerformingFinishingHammerBlow = false;
			StolenComp.PlayerStolenComp.Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			StolenComp.PlayerStolenComp.Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
			StolenComp.PlayerStolenComp.Player.UnblockCapabilities(PlayerMovementTags::GroundJump, this);
			bFinishingBlow = false;
			StolenComp.PlayerStolenComp.Player.StopSlotAnimationByAsset(StolenComp.PlayerFinalBlowAnim);			
			StolenComp.PlayerStolenComp.Player.ClearCameraSettingsByInstigator(this);
			StolenComp.PlayerStolenComp.Player.ClearPointOfInterestByInstigator(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(RecoveryTime > SMALL_NUMBER)
			return;

		if(AttackedTime > SMALL_NUMBER)
		{
			if(bNoTargetAttack || Time::GetGameTimeSince(AttackedTime) > HitDuration)
			{
				RecoveryTime = Time::GameTimeSeconds;
				StolenComp.bIdle = true;
			}				
			return;
		}

		if(AttackAlpha >= 1)
		{
			AttackedTime = Time::GameTimeSeconds;

			if(AutoAimTarget == nullptr || AutoAimTarget.Owner != HammerComp.HoldHammerComp.Owner)
				return;

			FHitResult Hit;
			Hit.Location = FinalLocation;
			Hit.ImpactPoint = FinalLocation;
			Hit.Actor = HammerComp.HoldHammerComp.Owner;
			if(HasControl())
				CrumbHitCharacter(Cast<AHazeActor>(HammerComp.HoldHammerComp.Owner), Hit);
			return;
		}

		if (TorDamageComp.bIsPerformingFinishingHammerBlow)
		{
			PerformFinishingBlowAttackVariant(DeltaTime);
			return;
		}

		if(!bNoTargetAttack)
			AimingLocation = AutoAimTarget.WorldLocation;
		else
			AimingLocation = AimingResults.AimOrigin + AimingResults.AimDirection * 1500.0;

		AccSpeed.AccelerateTo(7, 2.5, DeltaTime);
		AttackAlpha += DeltaTime * AccSpeed.Value;

		FVector OffsetDir = FVector::ZeroVector;
		FVector ForwardVector = (AimingLocation - StartLocation).GetSafeNormal();
		FRotator AddRotation = FRotator::ZeroRotator;

		if(AttackVariation == 0)
		{
			AddRotation = FRotator(0, 0, 90);
			OffsetDir = ForwardVector.Rotation().RightVector;
		}
		if(AttackVariation == 1)
		{
			AddRotation = FRotator(180, 0, 90);
			OffsetDir = -ForwardVector.Rotation().RightVector;
		}
		if(AttackVariation == 2)
		{
			AddRotation = FRotator(-90,  0, 90);
			OffsetDir = ForwardVector.Rotation().UpVector;
		}

		FVector MidLocation = StartLocation + OffsetDir * 800;
		FinalLocation = AimingLocation + OffsetDir * 100;
		PivotComp.Pivot.ActorLocation = BezierCurve::GetLocation_1CP(StartLocation, MidLocation, FinalLocation, AttackAlpha);

		FVector Direction = (FinalLocation - WhipUser.Owner.ActorLocation).GetSafeNormal2D();
		AccRotation.SpringTo((-Direction).Rotation().RightVector.Rotation() + AddRotation, 25, 0.5, DeltaTime);
		PivotComp.Pivot.ActorRotation = AccRotation.Value;
	}

	void PerformFinishingBlowAttackVariant(float DeltaTime)
	{
		AimingLocation = AutoAimTarget.WorldLocation;
		
		float ChargeTime = 0;

		// Start moving along curve after charge time
		if (ActiveDuration > ChargeTime)
		{
			AccSpeed.AccelerateTo(5, 5, DeltaTime);
			AttackAlpha += DeltaTime * AccSpeed.Value;
		}

		FVector OffsetDir = FVector::ZeroVector;
		FVector ForwardVector = (AimingLocation - StartLocation).GetSafeNormal();
		FRotator AddRotation = FRotator::ZeroRotator;
		
		AddRotation = FRotator(-135,  0, 90);
		OffsetDir = ForwardVector.Rotation().UpVector.RotateAngleAxis(45, ForwardVector);

		FVector MidLocation = StartLocation + OffsetDir * 600;
		FinalLocation = AimingLocation + OffsetDir * 100;
		PivotComp.Pivot.ActorLocation = BezierCurve::GetLocation_1CP(StartLocation, MidLocation, FinalLocation, AttackAlpha);

		// Start rotating after charge time
		if (ActiveDuration > ChargeTime)
		{
			FVector Direction = (FinalLocation - WhipUser.Owner.ActorLocation).GetSafeNormal2D();
			AccRotation.SpringTo((-Direction).Rotation().RightVector.Rotation() + AddRotation, 25, 0.5, DeltaTime);
		}

		PivotComp.Pivot.ActorRotation = AccRotation.Value;	
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbHitCharacter(AHazeActor Character, FHitResult Hit)
	{
		HitCharacter(Character, Hit);
	}

	void HitCharacter(AHazeActor Character, FHitResult Hit)
	{
		USkylineTorHammerEventHandler::Trigger_OnAttackHit(Owner, FSkylineTorHammerOnAttackHitEventData(Hit));
		USkylineTorHammerResponseComponent ResponseComp = USkylineTorHammerResponseComponent::Get(Character);
		if(ResponseComp != nullptr)
			ResponseComp.OnHit.Broadcast(1, EDamageType::MeleeBlunt, Owner);
	}
}