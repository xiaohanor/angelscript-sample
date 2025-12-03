class UMaxSecurityLaserCutterCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AMaxSecurityLaserCutter Cutter;

	AHazePlayerCharacter HangingPlayer;

	bool bLaserActive = false;

	FVector MoveDirection = FVector::ZeroVector;

	FQuat CurrentRotation;
	FQuat OriginRotation = FQuat::Identity;

	float ConeAngle = 16.0;
	float MinConeAngle = 14.0;
	float MaxConeAngle= 17.0;

	float RotationSpeed = 225.0;
	float LaserSpeed = 85.0;

	bool bTutorialCompleted = false;

	bool bPlayerStartedControlling = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Cutter = Cast<AMaxSecurityLaserCutter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (Cutter.IsStunned())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (Cutter.IsStunned())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if (!bTutorialCompleted)
		{
			FTutorialPrompt TutorialPrompt;
			TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
			TutorialPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
			TutorialPrompt.Text = Cutter.TutorialText;
			Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, Cutter.EmitterRoot, FVector(0.0, 0.0, -600.0), 0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (!bPlayerStartedControlling)
		{
			if (Cutter.bPlayerControlled)
			{
				CurrentRotation = FQuat(Cutter.CutterRoot.WorldRotation);
				FRotator Rot = FRotator::ZeroRotator;
				Rot.Yaw -= Cutter.ActorRotation.Yaw;
				OriginRotation = FQuat(Rot);
				bPlayerStartedControlling = true;
			}
		}

		if (bPlayerStartedControlling)
		{
			if (HasControl())
			{
				if (!bTutorialCompleted && IsActioning(ActionNames::PrimaryLevelAbility))
					CrumbFinishTutorial();

				FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

				FVector MoveInputXY = FVector(Input.Y, Input.X, 0);

				FVector Forward = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
				FRotator Rotation = FRotator::MakeFromX(Forward);
				float Speed = IsActioning(ActionNames::PrimaryLevelAbility) ? LaserSpeed : RotationSpeed;
				FVector CrosshairMove = Rotation.RotateVector(MoveInputXY) * Speed * DeltaTime;

				MoveDirection = Math::VInterpTo(MoveDirection, CrosshairMove, DeltaTime, 3.0);
				ControlMoveLaser(Cutter.LaserRoot.WorldLocation, MoveDirection, DeltaTime);
			}
			else
			{
				FMaxSecurityLaserCutterSyncedData SyncedData;
				Cutter.SyncComponent.GetCrumbValueStruct(SyncedData);
				Cutter.CutterRoot.SetRelativeLocation(SyncedData.RootRelativeLocation);
				Cutter.CutterRoot.SetWorldRotation(SyncedData.RootWorldRotation);
			}
		}

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.IgnorePlayers();
		Trace.UseLine();
		
		FVector TraceStartLoc = Cutter.LaserRoot.WorldLocation;
		FHitResult Hit = Trace.QueryTraceSingle(TraceStartLoc, TraceStartLoc - (Cutter.LaserRoot.UpVector * 3000.0));

		if (IsActioning(ActionNames::PrimaryLevelAbility) && !Cutter.bMegaLaserActivated)
		{
			Player.SetFrameForceFeedback(0.2, 0.2, 0.2, 0.2);
		}

		if (HasControl())
		{
			if (Cutter.bMegaLaserActivated)
			{
				bool bHittingWeakPoint = false;
				if (Hit.bBlockingHit)
				{
					AMaxSecurityLaserCutterWeakPoint WeakPoint = Cast<AMaxSecurityLaserCutterWeakPoint>(Hit.Actor);
					if (WeakPoint != nullptr)
					{
						WeakPoint.ControlHitByLaser(Hit);
						bHittingWeakPoint = true;
					}

					FMaxSecurityLaserCutterSyncedData SyncedData;
					Cutter.SyncComponent.GetCrumbValueStruct(SyncedData);
					SyncedData.bLaserIsImpactingWeakPoint = bHittingWeakPoint;
					Cutter.SyncComponent.SetCrumbValueStruct(SyncedData);
				}

				float FFFrequency = bHittingWeakPoint ? 30.0 : 15.0;
				float FFIntensity = bHittingWeakPoint ? 0.8 : 0.3;

				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
				FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
				Player.SetFrameForceFeedback(FF);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFinishTutorial()
	{
		if (bTutorialCompleted)
			return;

		bTutorialCompleted = true;
		Player.RemoveTutorialPromptByInstigator(this);
	}

	void ControlMoveLaser(FVector Origin, FVector Movement, float DeltaTime)
	{
		if (!ensure(HasControl()))
			return;

		if (!IsEnabled())
			return;

		FVector AngularMovement = FauxPhysics::Calculation::LinearToAngular(Cutter.CutterRoot.WorldLocation, 1000, Origin, Movement);
		AngularMovement = AngularMovement.ConstrainToPlane(GetConeDirectionWorldSpace());

		ControlApplyDeltaRotation(FauxPhysics::Calculation::VecToQuat(AngularMovement), DeltaTime);
	}

	void ControlApplyDeltaRotation(FQuat DeltaQuat, float DeltaTime)
	{
		if (!ensure(HasControl()))
			return;

		CurrentRotation = DeltaQuat * CurrentRotation;

		float HeightModifierSplineDist = Cutter.HeightModifierSpline.Spline.GetClosestSplineDistanceToWorldLocation(Cutter.EmitterRoot.WorldLocation);

		float HeightModifier = Math::GetMappedRangeValueClamped(FVector2D(200.0, 1850.0), FVector2D(600.0, -300.0), HeightModifierSplineDist);
		float HeightOffset = Math::FInterpTo(Cutter.CutterRoot.RelativeLocation.Z, HeightModifier, DeltaTime, 2.0);
		Cutter.CutterRoot.SetRelativeLocation(FVector(0.0, 0.0, HeightOffset));

		bool bZeroRotation = CurrentRotation.Angle < KINDA_SMALL_NUMBER;
		if (!bZeroRotation)
		{
			FVector RotationVec = FauxPhysics::Calculation::QuatToVec(CurrentRotation);

			RotationVec = RotationVec.ConstrainToPlane(GetConeDirectionWorldSpace());

			float CurConeAngle = Math::GetMappedRangeValueClamped(FVector2D(500.0, -200.0), FVector2D(MinConeAngle, MaxConeAngle), HeightOffset);
			float ConeAngleRad = Math::DegreesToRadians(CurConeAngle);
			float RotationAngle = RotationVec.SizeSquared();
			if (RotationAngle > Math::Square(ConeAngleRad))
			{
				FVector CollisionRotationNormal = RotationVec.SafeNormal;
				FVector ClampedRotation = CollisionRotationNormal * ConeAngleRad;
				CurrentRotation = FauxPhysics::Calculation::VecToQuat_Precise(ClampedRotation);
			}
		}

		if (Cutter.bPlayerControlled)
			Cutter.CutterRoot.SetWorldRotation(CurrentRotation * GetOriginWorldSpace());
		
		FMaxSecurityLaserCutterSyncedData SyncData;
		Cutter.SyncComponent.GetCrumbValueStruct(SyncData);
		SyncData.RootRelativeLocation = Cutter.CutterRoot.RelativeLocation;
		SyncData.RootWorldRotation = Cutter.CutterRoot.ComponentQuat;
		Cutter.SyncComponent.SetCrumbValueStruct(SyncData);
	}

	FVector GetConeDirectionWorldSpace() const
	{
		return (OriginRotation * FVector::UpVector).GetSafeNormal();
	}

	FQuat GetOriginWorldSpace() const
	{
		if (Cutter.CutterRoot.AttachParent != nullptr)
			return Cutter.CutterRoot.AttachParent.WorldTransform.Rotation * OriginRotation;
		else
			return OriginRotation;
	}
}