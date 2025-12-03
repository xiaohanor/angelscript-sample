asset SummitDominoCatapultZoeLaunchSheet of UHazeCapabilitySheet
{
	AddCapability(n"TeenDragonDominoCatapultGetLaunchedCapability");
}

class ASummitDominoCatapult : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent YawRotationPivot;

	UPROPERTY(DefaultComponent, Attach = YawRotationPivot)
	USceneComponent CatapultRotatePivot;

	UPROPERTY(DefaultComponent, Attach = CatapultRotatePivot)
	USceneComponent CounterWeightRoot;
	default CounterWeightRoot.SetAbsolute(false, true, false);

	UPROPERTY(DefaultComponent, Attach = CounterWeightRoot)
	UStaticMeshComponent CounterWeightMeshComp;

	// UPROPERTY(DefaultComponent, Attach = YawRotationPivot)
	// UStaticMeshComponent LeftRotateMeshComp;

	// UPROPERTY(DefaultComponent, Attach = LeftRotateMeshComp)
	// UTeenDragonTailAttackResponseComponent LeftRotateResponseComp;
	// default LeftRotateResponseComp.bIsPrimitiveParentExclusive = true;
	// default LeftRotateResponseComp.bShouldStopPlayer = true;

	// UPROPERTY(DefaultComponent, Attach = YawRotationPivot)
	// UStaticMeshComponent RightRotateMeshComp;

	// UPROPERTY(DefaultComponent, Attach = RightRotateMeshComp)
	// UTeenDragonTailAttackResponseComponent RightRotateResponseComp;
	// default RightRotateResponseComp.bIsPrimitiveParentExclusive = true;
	// default RightRotateResponseComp.bShouldStopPlayer = true;

	// UPROPERTY(DefaultComponent)
	// UStaticMeshComponent AcidShootMesh;

	// UPROPERTY(DefaultComponent, Attach = AcidShootMesh)
	// UAcidResponseComponent AcidResponseComp;

	// UPROPERTY(DefaultComponent, Attach = AcidShootMesh)
	// UTeenDragonAcidAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	// default CapabilityComp.DefaultCapabilityClasses.Add(USummitDominoCatapultRollRotateCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitDominoCatapultFireCapability);
	// default CapabilityComp.DefaultCapabilityClasses.Add(USummitDominoCatapultResetCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitDominoCatapultWindUpCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitDominoCatapultWindDownCapability);

	UPROPERTY(DefaultComponent, Attach = CatapultRotatePivot)
	USceneComponent LaunchLocation;

	UPROPERTY(DefaultComponent, Attach = CatapultRotatePivot)
	UHazeMovablePlayerTriggerComponent PlayerCheckVolume;

	UPROPERTY(DefaultComponent, Attach = YawRotationPivot)
	USceneComponent WindUpRotateRoot;

	UPROPERTY(DefaultComponent, Attach = WindUpRotateRoot)
	UStaticMeshComponent WindUpHitMeshDown;

	UPROPERTY(DefaultComponent, Attach = WindUpHitMeshDown)
	UTeenDragonTailAttackResponseComponent WindUpResponseCompDown;
	default WindUpResponseCompDown.bIsPrimitiveParentExclusive = true;
	default WindUpResponseCompDown.bShouldStopPlayer = true;

	UPROPERTY(DefaultComponent, Attach = WindUpRotateRoot)
	UStaticMeshComponent WindUpHitMeshUp;

	UPROPERTY(DefaultComponent, Attach = WindUpHitMeshUp)
	UTeenDragonTailAttackResponseComponent WindUpResponseCompUp;
	default WindUpResponseCompUp.bIsPrimitiveParentExclusive = true;
	default WindUpResponseCompUp.bShouldStopPlayer = true;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerSheets_Zoe.Add(SummitDominoCatapultZoeLaunchSheet);

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTempLogComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitDominoCatapultDummyComponent DummyComp;
#endif

	// UPROPERTY(EditAnywhere, Category = "Roll Rotate")
	// int TimesToHitForMaxTurn = 2;

	// UPROPERTY(EditAnywhere, Category = "Roll Rotate")
	// int TurnOverShootHits = 1;

	// UPROPERTY(EditAnywhere, Category = "Roll Rotate")
	// float MaxTurnDegrees = 45.0;

	UPROPERTY(EditAnywhere, Category = "Roll Rotate")
	float TimeToCompleteRotation = 1.0;

	UPROPERTY(EditAnywhere, Category = "Roll Rotate")
	FRuntimeFloatCurve RollRotationCurve;
	default RollRotationCurve.AddDefaultKey(0.0, 0.0);
	default RollRotationCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Roll Wind Up")
	float RollWindUpDuration = 1.5;

	UPROPERTY(EditAnywhere, Category = "Roll Wind Up")
	FRuntimeFloatCurve WindUpRotationCurve;
	default WindUpRotationCurve.AddDefaultKey(0.0, 0.0);
	default WindUpRotationCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Roll Wind Up")
	int RollWindUpHitsRequired = 4;

	UPROPERTY(EditAnywhere, Category = "Roll Wind Up")
	FRuntimeFloatCurve WindUpRotateBackAccelerationCurve;
	default WindUpRotateBackAccelerationCurve.AddDefaultKey(0.0, 0.0);
	default WindUpRotateBackAccelerationCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Roll Wind Up")
	float MaxWindUpRotateBackSpeed = 50.0;

	UPROPERTY(EditAnywhere, Category = "Roll Wind Up")
	float WindUpDelayBeforeGoingBack = 0.5;

	// After what delay that the rotate back speed is at max
	UPROPERTY(EditAnywhere, Category = "Roll Wind Up")
	float MaxWindUpRotateBackSpeedDelay = 2.0;

	UPROPERTY(EditAnywhere, Category = "Release Statue")
	ASummitCatapultLauncherStatue Statue;

	UPROPERTY(EditAnywhere, Category = "Release Statue")
	float StatueHandsInTheWayPercentage = 0.05;

	UPROPERTY(EditAnywhere, Category = "Release Statue")
	float StatuePercentageCountsAsGrabbing = 0.1;

	UPROPERTY(EditAnywhere, Category = "Release Statue")
	float StatueHoldLastInterpSpeed = 50.0;

	UPROPERTY(EditAnywhere, Category = "Release Mechanism")
	int AcidHitsRequiredToRelease = 20;

	UPROPERTY(EditAnywhere, Category = "Release Mechanism")
	float ShootRotateDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Release Mechanism")
	FRuntimeFloatCurve ShootRotationCurve;
	default ShootRotationCurve.AddDefaultKey(0.0, 0.0);
	default ShootRotationCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Release Mechanism")
	float ShootRotateMaxDegrees = 90.0;

	UPROPERTY(EditAnywhere, Category = "Reset")
	float ResetDelay = 1.0;

	UPROPERTY(EditAnywhere, Category = "Reset")
	float ResetDuration = 5.0;

	UPROPERTY(EditInstanceOnly, Category = "Launch")
	AActor Target;

	UPROPERTY(EditAnywhere, Category = "Launch")
	FVector TargetLocationOffset;

	UPROPERTY(EditAnywhere, Category = "Launch")
	float LaunchHorizontalSpeed = 10000.0;

	UPROPERTY(EditAnywhere, Category = "Launch")
	float LaunchGravityAmount = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Launch")
	FApplyPointOfInterestSettings InBasketPoiApplySettings;

	UPROPERTY(EditAnywhere, Category = "Launch")
	UHazeCameraSettingsDataAsset InBasketCameraSettings;

	UPROPERTY(EditAnywhere, Category = "Test")
	bool bTestStartDown = false;

	UPROPERTY(EditAnywhere, Category = "Test")
	bool bCatapultRotationInEditorIsUp = false;

	UPROPERTY(EditInstanceOnly)
	AAcidStatue AcidStatue;

	float TimeLastHitByRoll;
	float TimeLastHitByWindUpRoll;
	float TimeLastStoppedWindingUp;
	float TimeLastFired;

	FQuat TargetQuat;
	FQuat StartQuat;
	FQuat FireTargetQuat;

	FVector EstimatedLaunchLocation;

	int TimesTurnedToLeft = 0;
	// int AcidHits = 0;

	bool bIsPrimed = false;

	TOptional<AHazePlayerCharacter> ZoeInVolume;

	float TargetWindUpDegrees = 0.0;
	float CurrentWindUpDegrees = 0.0;
	float StartWindUpDegrees = 0.0;

	bool bAcidActivated;

	bool bWindingUp = false;
	bool bWindUpHitEnd = false;
	bool bStatueIsHoldingCatapult = false;
	bool bIsFiring = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// LeftRotateResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRollLeft");
		// RightRotateResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRollRight");

		// AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		if(AcidStatue != nullptr)
			AcidStatue.OnCraftTempleAcidStatueActivated.AddUFunction(this, n"OnCraftTempleAcidStatueActivated");

		EstimatedLaunchLocation = LaunchLocation.WorldLocation;

		// CatapultRotatePivot.RelativeRotation = FRotator(0, 0, 0);
		// YawRotationPivot.RelativeRotation += FRotator(0, MaxTurnDegrees, 0);
		CatapultRotatePivot.RelativeRotation = FRotator(0.0, 0.0, ShootRotateMaxDegrees);
		FireTargetQuat = (CatapultRotatePivot.RelativeRotation).Quaternion();
		// FireTargetQuat = (CatapultRotatePivot.RelativeRotation + FRotator(0, 0, ShootRotateMaxDegrees)).Quaternion();
		TargetQuat = YawRotationPivot.RelativeRotation.Quaternion();

		PlayerCheckVolume.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnteredVolume");
		PlayerCheckVolume.OnPlayerLeave.AddUFunction(this, n"OnPlayerExitedVolume");

		WindUpResponseCompDown.OnHitByRoll.AddUFunction(this, n"WindUpHitRollDownMesh");
		WindUpResponseCompUp.OnHitByRoll.AddUFunction(this, n"WindUpHitRollUpMesh");

		if(bTestStartDown)
		{
			CurrentWindUpDegrees = MaxWindUpDegrees;
			WindUpRotateRoot.RelativeRotation = FRotator(0.0, 0.0, -CurrentWindUpDegrees);
			RotateCatapultBasedOnDegrees();
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bCatapultRotationInEditorIsUp)
			CatapultRotatePivot.RelativeRotation = FRotator(0.0, 0.0, ShootRotateMaxDegrees);
		else
			CatapultRotatePivot.RelativeRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Value("Current Wind Up Degrees", CurrentWindUpDegrees)
			.Value("Target Wind Up Degrees", TargetWindUpDegrees)
			.Value("Start Wind Up Degrees", StartWindUpDegrees)
		;

		if(Statue != nullptr)
		{
			if(IsInLastHandPercentage()
			&& Statue.HandsCountAsGrabbing())
				bStatueIsHoldingCatapult = true;
		}

		if(bStatueIsHoldingCatapult)
		{
			CurrentWindUpDegrees = Math::FInterpConstantTo(CurrentWindUpDegrees, MaxWindUpDegrees, DeltaSeconds, StatueHoldLastInterpSpeed);
			RotateCatapultBasedOnDegrees();
		}
	}

	UFUNCTION()
	private void WindUpHitRollUpMesh(FRollParams Params)
	{
		GetHitByRoll(true, Params.HitLocation, Params.PlayerInstigator);
	}

	UFUNCTION()
	private void WindUpHitRollDownMesh(FRollParams Params)
	{
		GetHitByRoll(false, Params.HitLocation, Params.PlayerInstigator);
	}

	private void GetHitByRoll(bool bUpper, FVector HitLocation, AHazePlayerCharacter Player)
	{
		FVector FlatHitLocation = HitLocation.ConstrainToPlane(ActorForwardVector);
		FVector FlatPlayerLocation = Player.ActorCenterLocation.ConstrainToPlane(ActorForwardVector);
		FVector DirToHit = (FlatPlayerLocation - FlatHitLocation).GetSafeNormal();


		FVector HitCompareVector = bUpper ?
									    WindUpHitMeshUp.UpVector :
									    WindUpHitMeshDown.UpVector;

		TEMPORAL_LOG(this)
			.DirectionalArrow("Flat Dir to Hit", HitLocation, DirToHit * 500, 20, 400, FLinearColor::LucBlue)
			.DirectionalArrow("Hit Compare Vector", HitLocation, HitCompareVector * 500, 20, 400, FLinearColor::Red)
		;

		float DirDotForward = DirToHit.DotProduct(HitCompareVector);
		bool bHitForward;
		if (DirDotForward > 0.2)
			bHitForward = true;
		else if(DirDotForward < -0.2)
			bHitForward = false;
		// Didn't hit it in the correct direction
		else
			return;

		float AdditionalRoll = 180.0;
		if(!bHitForward)
			AdditionalRoll *= -1.0;

		StartWindUpDegrees = CurrentWindUpDegrees;
		TargetWindUpDegrees += AdditionalRoll;
		TimeLastHitByWindUpRoll = Time::GameTimeSeconds;
		bWindUpHitEnd = false;
	}

	float GetMaxWindUpDegrees() const property
	{
		float MaxDegrees = RollWindUpHitsRequired * 180.0;
		return MaxDegrees;
	}

	float GetMaxWindUpDegreesCurrently() const property
	{
		float MaxDegrees = RollWindUpHitsRequired * 180.0;
		if(Statue != nullptr
		&& Statue.HandsAreDown())
			MaxDegrees *= (1 - StatueHandsInTheWayPercentage);
		return MaxDegrees;
	}

	void RotateCatapultBasedOnDegrees()
	{
		float Alpha = CurrentWindUpDegrees / MaxWindUpDegrees;
		float RotationDegrees = (1 - Alpha) * 90.0;
		CatapultRotatePivot.RelativeRotation = FRotator(0.0, 0.0, RotationDegrees); 
	}

	UFUNCTION()
	private void OnCraftTempleAcidStatueActivated()
	{
		bAcidActivated = true;
	}

	UFUNCTION()
	private void OnPlayerEnteredVolume(AHazePlayerCharacter Player)
	{
		ZoeInVolume.Set(Player);

		FHazePointOfInterestFocusTargetInfo Poi;
		Poi.SetFocusToComponent(YawRotationPivot);
		Poi.LocalOffset = FVector(0, 20000, 500);

		Player.ApplyCameraSettings(InBasketCameraSettings, 1.5, this, EHazeCameraPriority::High);
		Player.ApplyPointOfInterest(this, Poi, InBasketPoiApplySettings, 2.0, EHazeCameraPriority::Medium);
	}

	UFUNCTION()
	private void OnPlayerExitedVolume(AHazePlayerCharacter Player)
	{
		ZoeInVolume.Reset();

		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);
	}

	bool IsInLastHandPercentage() const
	{
		float Alpha = CurrentWindUpDegrees / MaxWindUpDegrees;
		return (1 - Alpha) <= StatueHandsInTheWayPercentage;
	}


	// UFUNCTION()
	// private void OnHitByRollLeft(FRollParams Params)
	// {
	// 	if (TimesTurnedToLeft + 1 > TimesToHitForMaxTurn + TurnOverShootHits)
	// 		return;
	// 	GetHitByRoll(false, Params.HitLocation, Params.PlayerInstigator);
	// 	++TimesTurnedToLeft;
	// }

	// UFUNCTION()
	// private void OnHitByRollRight(FRollParams Params)
	// {
	// 	if (TimesTurnedToLeft - 1 < 0)
	// 		return;
	// 	GetHitByRoll(true, Params.HitLocation, Params.PlayerInstigator);
	// 	--TimesTurnedToLeft;
	// }

	// private void GetHitByRoll(bool bRight, FVector HitLocation, AHazePlayerCharacter Player)
	// {
	// 	// Cap rotation
	// 	float AdditionalYaw = MaxTurnDegrees / TimesToHitForMaxTurn;
	// 	if (!bRight)
	// 		AdditionalYaw *= -1;

	// 	FVector FlatHitLocation = HitLocation.ConstrainToPlane(FVector::UpVector);
	// 	FVector FlatPlayerLocation = Player.ActorLocation.ConstrainToPlane(FVector::UpVector);
	// 	FVector DirToHit = (FlatPlayerLocation - FlatHitLocation).GetSafeNormal();

	// 	FVector HitCompareVector = bRight ?
	// 								   RightRotateMeshComp.ForwardVector :
	// 								   LeftRotateMeshComp.ForwardVector;

	// 	// Didn't hit it in the correct direction
	// 	if (DirToHit.DotProduct(HitCompareVector) < 0.4)
	// 		return;

	// 	StartQuat = YawRotationPivot.RelativeRotation.Quaternion();
	// 	TargetQuat *= FRotator(0, AdditionalYaw, 0.0).Quaternion();

	// 	auto TargetRotation = TargetQuat.Rotator();
	// 	TargetQuat = TargetRotation.Quaternion();

	// 	TimeLastHitByRoll = Time::GameTimeSeconds;
	// }

	// UFUNCTION()
	// private void OnAcidHit(FAcidHit Hit)
	// {
	// 	if (!bIsPrimed)
	// 		return;

	// 	++AcidHits;
	// }

	private void RotateTowardsTarget(float TimeSinceHit)
	{
		float AlphaTime = TimeSinceHit / TimeToCompleteRotation;
		float AlphaToReachTarget = RollRotationCurve.GetFloatValue(AlphaTime);

		if (Math::IsNearlyEqual(AlphaToReachTarget, 1.0))
			AlphaToReachTarget = 1.0;

		YawRotationPivot.RelativeRotation = FQuat::Slerp(StartQuat, TargetQuat, AlphaToReachTarget).Rotator();
	}

	FVector GetTargetLocation() const property
	{
		FVector Location = Target.ActorLocation;
		Location += YawRotationPivot.WorldTransform.TransformVector(TargetLocationOffset);
		return Location;
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Launch")
	void RotateToFaceTarget()
	{
		FVector DirToTarget = (TargetLocation - ActorLocation).GetSafeNormal();
		DirToTarget = DirToTarget.ConstrainToPlane(FVector::UpVector);
		SetActorRotation(FRotator::MakeFromYZ(DirToTarget, FVector::UpVector));
	}

	UFUNCTION(CallInEditor, Category = "Launch")
	void RestartLaunchSimulation()
	{
		bLaunchValuesWereModifiedThisFrame = true;
	}

	bool bLaunchValuesWereModifiedThisFrame = false;
	float PreviousFrameLaunchHorizontalSpeed;
	float PreviousFrameLaunchGravityAmount;

	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (PreviousFrameLaunchGravityAmount != LaunchGravityAmount || PreviousFrameLaunchHorizontalSpeed != LaunchHorizontalSpeed)
			bLaunchValuesWereModifiedThisFrame = true;
		else
			bLaunchValuesWereModifiedThisFrame = false;

		PreviousFrameLaunchHorizontalSpeed = LaunchHorizontalSpeed;
		PreviousFrameLaunchGravityAmount = LaunchGravityAmount;
	}
#endif
};

#if EDITOR
class USummitDominoCatapultDummyComponent : UActorComponent
{};
class USummitDominoCatapultComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitDominoCatapultDummyComponent;

	ASummitDominoCatapult Catapult;

	FVector SimulatedLocation;
	FVector SimulatedVelocity;
	FVector SimulatedTargetLocation;

	float LastTimeStamp;
	float TimeToReachTarget;
	float SimulateDuration;

	const float MaxSimulateDuration = 2.0;
	const float DragonCapsuleRadius = 130.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitDominoCatapultDummyComponent>(Component);
		if (Comp == nullptr)
			return;
		Catapult = Cast<ASummitDominoCatapult>(Comp.Owner);
		if (Catapult == nullptr)
			return;

		if (Catapult.Target != nullptr)
			SimulatedTargetLocation = Catapult.TargetLocation;
		else
			SimulatedTargetLocation = Catapult.ActorLocation + (Catapult.ActorForwardVector * Catapult.LaunchHorizontalSpeed * 2) + Catapult.ActorUpVector * Catapult.LaunchGravityAmount;

		float Radius = 250.0;
		FLinearColor Color = FLinearColor::Purple;

		DrawWireSphere(SimulatedTargetLocation, Radius, Color, 5, 36);
		Debug::DrawDebugString(SimulatedTargetLocation + FVector::UpVector * Radius, "Target Location", Color);

		VisualizeTrajectory();

		Color = FLinearColor::Yellow;
		DrawWireSphere(Catapult.LaunchLocation.WorldLocation, Radius, Color, 5, 36);
		Debug::DrawDebugString(Catapult.LaunchLocation.WorldLocation + FVector::UpVector * Radius, "Launch Location", Color);

		VisualizeSimulatedPlayer();
	}

	void VisualizeTrajectory()
	{
		FVector Origin = Catapult.LaunchLocation.WorldLocation;
		FVector Target = SimulatedTargetLocation;

		FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Origin, Target, DragonGravity, Catapult.LaunchHorizontalSpeed);
		FVector HighestPoint = Trajectory::TrajectoryHighestPoint(Origin, Velocity, DragonGravity, FVector::UpVector);

		FTransform WorldTransform = FTransform::MakeFromXZ(FVector::ForwardVector, FVector::DownVector);
		FVector LocalOrigin = WorldTransform.InverseTransformPosition(Origin);
		FVector LocalDestination = WorldTransform.InverseTransformPosition(Target);
		FVector LocalHighestPoint = WorldTransform.InverseTransformPosition(HighestPoint);

		float ParabolaHeight = LocalHighestPoint.Z - (LocalOrigin.Z < LocalDestination.Z ? LocalOrigin.Z : LocalDestination.Z);
		float ParabolaBase = LocalOrigin.DistXY(LocalDestination);

		float ParabolaLengthSqrRt = Math::Sqrt(4 * Math::Square(ParabolaHeight) + Math::Square(ParabolaBase));
		float ParabolaLength = ParabolaLengthSqrRt + (Math::Square(ParabolaBase) / (2 * ParabolaBase)) * Math::Loge((2 * ParabolaHeight + ParabolaLengthSqrRt) / ParabolaBase);
		// ¯\_(ツ)_/¯
		ParabolaLength *= 2.5;

		Trajectory::FTrajectoryPoints Points = Trajectory::CalculateTrajectory(Origin, ParabolaLength, Velocity, DragonGravity, 1.5);

		for (int i = 0; i < Points.Positions.Num() - 1; ++i)
		{
			FVector Start = Points.Positions[i];
			FVector End = Points.Positions[i + 1];
			bool bDone = false;

			if ((HighestPoint - Target).GetSafeNormal().DotProduct((End - Target).GetSafeNormal()) < 0.0)
			{
				End = Target;
				bDone = true;
			}

			DrawLine(Start, End, FLinearColor::Yellow, 10);
			if (bDone)
				break;
		}
	}

	void VisualizeSimulatedPlayer()
	{
		float TimeStamp = Time::GetGameTimeSeconds();
		float DeltaTime = TimeStamp - LastTimeStamp;
		LastTimeStamp = TimeStamp;

		TimeToReachTarget -= DeltaTime;

		bool bRestartSimulation = TimeToReachTarget <= 0.0;

		if (Catapult.bLaunchValuesWereModifiedThisFrame)
			bRestartSimulation = true;
		if (bRestartSimulation)
		{
			FVector Start = Catapult.LaunchLocation.WorldLocation;
			FVector End = SimulatedTargetLocation;

			SimulatedLocation = Start;
			SimulatedVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Start, End, DragonGravity, Catapult.LaunchHorizontalSpeed);

			FVector DeltaToTarget = (End - Start);
			FVector VerticalToTarget = DeltaToTarget.ProjectOnToNormal(FVector::UpVector);
			FVector HorizontalToTarget = DeltaToTarget - VerticalToTarget;
			float HorizontalDistance = HorizontalToTarget.Size();

			FVector VerticalVelocity = SimulatedVelocity.ProjectOnToNormal(FVector::UpVector);
			FVector HorizontalVelocity = SimulatedVelocity - VerticalVelocity;
			float HorizontalSpeed = HorizontalVelocity.Size();
			TimeToReachTarget = HorizontalDistance / HorizontalSpeed;
			Catapult.bLaunchValuesWereModifiedThisFrame = false;
		}

		SimulatedVelocity += FVector::DownVector * DragonGravity * DeltaTime;
		SimulatedLocation += SimulatedVelocity * DeltaTime;

		DrawWireSphere(SimulatedLocation, DragonCapsuleRadius, FLinearColor::LucBlue, 5, 48);
	}

	float GetDragonGravity() const property
	{
		return Catapult.LaunchGravityAmount;
	}
}
#endif