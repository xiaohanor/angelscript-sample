class UBattlefieldHoverboardGroundedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = n"Hoverboard";  

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;

	UPlayerMovementComponent MoveComp;

	UMovementSteppingSettings SteppingSettings;

	FHazeAcceleratedVector AccGroundNormal;

	const float NormalAccelerationDuration = 0.1;
	const float StepDownFractionMin = 0.0;
	const float NormalDeltaAngleForStepDownMin = 40.0;

	float StartStepDownFraction;

	UPhysicalMaterial LastPhysMat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);

		SteppingSettings = UMovementSteppingSettings::GetSettings(Player);

		AccGroundNormal.SnapTo(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GrindComp.IsGrinding())
			return false;

		if(MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GrindComp.IsGrinding())
			return true;

		if(MoveComp.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		JumpComp.bHasTouchedGroundSinceLastJump = true;
		StartStepDownFraction = SteppingSettings.StepDownSize.Value;
		HoverboardComp.bIsGrounded = true;

		FBattlefieldHoverboardOnGroundedParams Params;
		auto PhysMat = MoveComp.GroundContact.AudioPhysMaterial;
		if(PhysMat == nullptr)
		{
			FHazeTraceSettings TraceSettings;
			TraceSettings.TraceWithMovementComponent(MoveComp);
			PhysMat = AudioTrace::GetPhysMaterialFromHit(MoveComp.GroundContact.InternalHitResult, TraceSettings);
		}
		Params.GroundPhysicalMaterial = PhysMat;
		UBattlefieldHoverboardEffectHandler::Trigger_OnGrounded(HoverboardComp.Hoverboard, Params);

		LastPhysMat = Params.GroundPhysicalMaterial;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.TimeLastBecameAirborne = Time::GameTimeSeconds;
		Player.ClearSettingsByInstigator(this);
		HoverboardComp.bIsGrounded = false;

		SteppingSettings.bOverride_StepDownSize = true;
		SteppingSettings.StepDownSize = FMovementSettingsValue::MakePercentage(StartStepDownFraction);

		UBattlefieldHoverboardEffectHandler::Trigger_OnLeftGround(HoverboardComp.Hoverboard);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		JumpComp.bHasTouchedGroundSinceLastJump = true;

		FHazeTraceSettings GroundTrace;
		GroundTrace.TraceWithPlayerProfile(Player);
		GroundTrace.UseLine();
		GroundTrace.IgnoreActor(Player);
		GroundTrace.IgnoreActor(HoverboardComp.Hoverboard);

		FVector Start = Player.ActorLocation 
			+ (JumpComp.LastGroundNormal * 100)
			+ (Player.ActorVelocity.GetSafeNormal() * 200);
		FVector End = Start - (JumpComp.LastGroundNormal * 200.0);
		auto Hit = GroundTrace.QueryTraceSingle(Start, End);

		TEMPORAL_LOG(Player, "Hoverboard Adaptable Stepdown")
			.Arrow("Trace", Start, End, 10, 20, FLinearColor::Blue)
		;

		if(Hit.bBlockingHit)
		{
			TEMPORAL_LOG(Player, "Hoverboard Adaptable Stepdown")
				.Sphere("Trace Hit", Hit.ImpactPoint, 10, FLinearColor::Blue, 2)
			;
			AccGroundNormal.AccelerateTo(Hit.Normal, NormalAccelerationDuration, DeltaTime);
		}
		else
		{
			// Didn't find the ground, using placeholder direction which is super far away
			AccGroundNormal.AccelerateTo(FVector::UpVector, NormalAccelerationDuration, DeltaTime);
		}

		float DegreesToLastNormal = AccGroundNormal.Value.GetAngleDegreesTo(Hit.Normal);
		float DeltaDegreesToMaxAlpha = Math::GetPercentageBetweenClamped(0, NormalDeltaAngleForStepDownMin, DegreesToLastNormal);

		float LerpedStepDownValue = Math::Lerp(StartStepDownFraction, StepDownFractionMin, DeltaDegreesToMaxAlpha);
		FMovementSettingsValue StepDownValue = FMovementSettingsValue::MakePercentage(LerpedStepDownValue);

		SteppingSettings.bOverride_StepDownSize = true;
		SteppingSettings.StepDownSize = StepDownValue;

		TEMPORAL_LOG(Player, "Hoverboard Adaptable Stepdown")
			.DirectionalArrow("Comparing Vector", Player.ActorLocation, AccGroundNormal.Value * 1000, 10, 20, FLinearColor::White)
			.Value("Step Down Fraction", StepDownValue.Value)
		;
		JumpComp.LastGroundNormal = MoveComp.CurrentGroundImpactNormal;

		if(LastPhysMat != MoveComp.GroundContact.AudioPhysMaterial)
		{
			FBattlefieldHoverboardOnGroundMaterialChangedParams Params;
			Params.NewGroundPhysicalMaterial = MoveComp.GroundContact.AudioPhysMaterial;
			LastPhysMat = Params.NewGroundPhysicalMaterial;
			UBattlefieldHoverboardEffectHandler::Trigger_OnGroundMaterialChanged(HoverboardComp.Hoverboard, Params);
		}
	}
};