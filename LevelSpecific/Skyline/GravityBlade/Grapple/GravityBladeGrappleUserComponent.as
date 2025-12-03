event void FGravityBladeGrappleUserComponentActivationSignature();

UCLASS(Abstract, HideCategories = "ComponentTick ComponentReplication Debug Activation Variable Cooking Disable Tags AssetUserData Collision")
class UGravityBladeGrappleUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Gravity Blade")
	FGravityBladeGrappleAnimationData AnimationData;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gravity Blade")
	TSubclassOf<UCrosshairWidget> CrosshairWidgetClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gravity Blade")
	TSubclassOf<UTargetableWidget> GrappleWidgetClass;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gravity Blade")
	UHazeCameraSpringArmSettingsDataAsset GrappleCameraSettings;

	UPROPERTY(BlueprintReadOnly, Category = "Gravity Blade")
	UGravityBladeGrappleCameraBlend GrappleCameraBlend;
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Blade")
	UGravityBladeGrappleSettings DefaultSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Gravity Blade|Eject")
	UAnimSequence GrappleEjectAnimation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gravity Blade|Eject")
	UHazeCameraSpringArmSettingsDataAsset GrappleEjectCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Gravity Blade")
	UForceFeedbackEffect GrappleLandingForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category = "Gravity Blade")
	TSubclassOf<UCameraShakeBase> GrappleLandingCameraShake;

	FGravityBladeGrappleData AimGrappleData;
	FGravityBladeGrappleData ActiveGrappleData;
	FGravityBladeGravityAlignSurface ActiveAlignSurface;
	TArray<FInstigator> AlignQueryDisablers;
	UGravityBladeGrappleTargetWidget TargetWidget;

	// Pull duration is dynamic, but we need to know it to keep the camera
	//  transition over the same duration
	float GrapplePullDuration;

	// Events
	UPROPERTY()
	FGravityBladeGrappleUserComponentActivationSignature OnActivation;

	private AHazePlayerCharacter Player;
	private UPlayerAimingComponent AimComp;
	private UPlayerTargetablesComponent PlayerTargetablesComp;
	private UPlayerMovementComponent MoveComp;

	UGravityBladeGrappleSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);	

		Settings = UGravityBladeGrappleSettings::GetSettings(Player);

		AimComp = UPlayerAimingComponent::Get(Owner);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);

		if(DefaultSettings != nullptr)
			Player.ApplyDefaultSettings(DefaultSettings);
	}

	// FB TODO: Quick fix
	UGravityBladeUserComponent GetBladeComp() const property
	{
		return UGravityBladeUserComponent::Get(Owner);
	}

	FGravityBladeGrappleData QueryAimGrappleData() const
	{
		UGravityBladeGrappleComponent GrappleComp = PlayerTargetablesComp.GetPrimaryTarget(UGravityBladeGrappleComponent);
		if (GrappleComp == nullptr)
			return FGravityBladeGrappleData();

		// Combat grapples don't actually change the world up
		if (GrappleComp.bIsCombatGrapple)
		{
			// Reject grapples that are too close. We don't do this in CheckTargetable because we still
			// want nearby enemies to block grapple targeting for distant enemies
			if (Player.ActorLocation.Distance(GrappleComp.WorldLocation) < GrappleComp.MinimumDistanceFromPlayer)
				return FGravityBladeGrappleData();

			FGravityBladeGrappleData GrappleData = FGravityBladeGrappleData(
				GrappleComp,
				GrappleComp.WorldLocation,
				FQuat::MakeFromZX(Player.MovementWorldUp, GrappleComp.ForwardVector),
				nullptr,
				nullptr,
			);
			GrappleData.bIsCombatGrapple = true;
			GrappleData.bAlwaysAirGrapple = GrappleComp.bAlwaysAirGrapple;
			return GrappleData;
		}

		auto ShiftComp = UGravityBladeGravityShiftComponent::Get(GrappleComp.Owner);
		auto ResponseComponent = UGravityBladeGrappleResponseComponent::Get(GrappleComp.Owner);

		FVector TargetPoint = GrappleComp.WorldLocation;
		FVector ForwardVector = (GrappleComp.WorldLocation - Player.ActorCenterLocation).GetSafeNormal();
		FVector UpVector = GrappleComp.ForwardVector;

		if (ShiftComp != nullptr && ShiftComp.Type != EGravityBladeGravityShiftType::Surface)
			UpVector = ShiftComp.GetShiftDirection(GrappleComp.WorldLocation);

		// Capsule trace to figure out where the player should stand in relation
		//  to the impact point by pulling back and stepping down
		const float CapsuleRadius = Player.CapsuleComponent.ScaledCapsuleRadius;
		const float CapsuleHalfHeight = Player.CapsuleComponent.ScaledCapsuleHalfHeight;
		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerCharacter);
		Trace.UseCapsuleShape(CapsuleRadius, CapsuleHalfHeight, FQuat::MakeFromZX(UpVector, ForwardVector));

		FHitResult OutCapsuleTargetHit = Trace.QueryTraceSingle(
			TargetPoint + (UpVector * (CapsuleHalfHeight + GravityBladeGrapple::PullbackDistance)),
			TargetPoint - (UpVector * (GravityBladeGrapple::StepDownHeight + GravityBladeGrapple::PullbackDistance))
		);

		if (OutCapsuleTargetHit.bStartPenetrating || !OutCapsuleTargetHit.bBlockingHit)
			return FGravityBladeGrappleData();

		return FGravityBladeGrappleData(GrappleComp,
			OutCapsuleTargetHit.Location - (UpVector * CapsuleHalfHeight),
			FQuat::MakeFromZX(UpVector, ForwardVector),
			ResponseComponent,
			ShiftComp);
	}

	FGravityBladeGravityAlignSurface QueryGravityAlignSurface() const
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerCharacter); 
		auto HitResult = Trace.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation - (Player.MovementWorldUp * GravityBladeGrapple::AlignSurfaceTraceRange));

		UGravityBladeGravityShiftComponent SurfaceShiftComp = nullptr;
		if (HitResult.bBlockingHit && HitResult.Actor != nullptr)
		{
			SurfaceShiftComp = UGravityBladeGravityShiftComponent::Get(HitResult.Actor);
			if (SurfaceShiftComp != nullptr && !SurfaceShiftComp.bEnableAutoShift)
				SurfaceShiftComp = nullptr;
		}

		FGravityBladeGravityAlignSurface AlignSurface;
		AlignSurface.SurfaceComponent = HitResult.Component;
		AlignSurface.SurfaceLocation = HitResult.ImpactPoint;
		AlignSurface.ShiftComponent = SurfaceShiftComp;
		AlignSurface.SurfaceNormal = HitResult.Normal;
		return AlignSurface;
	}

	UFUNCTION(BlueprintPure)
	bool HasAimingTarget() const
	{
		return AimGrappleData.IsValid();
	}

	UFUNCTION(BlueprintPure)
	bool IsGrappling()
	{
		return ActiveGrappleData.IsValid();
	}
}