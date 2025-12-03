class URemoteHackableSmokeRobotCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	UMaxSecurityLaserClusterAudioDataComponent AudioDataComp;
	ARemoteHackableSmokeRobot SmokeRobot;
	bool bSmokeActive = false;

	float SmokeAlpha = 0.0;
	float MaxSmokeRange = 800.0;

	bool bDebug = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		AudioDataComp = UMaxSecurityLaserClusterAudioDataComponent::GetOrCreate(Owner);

		SmokeRobot = Cast<ARemoteHackableSmokeRobot>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.BlockCapabilities(CapabilityTags::Movement, this);

		Player.BlockCapabilities(n"Death", this);
		Player.BlockCapabilities(n"ContextualMoves", this);

		SmokeAlpha = 0.0;
		ActivateSmoke();

		URemoteHackableSmokeRobotEventHandler::Trigger_StartHacked(SmokeRobot);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);

		Player.UnblockCapabilities(n"Death", this);
		Player.UnblockCapabilities(n"ContextualMoves", this);

		Player.ClearGravityDirectionOverride(this);

		Player.RemoveTutorialPromptByInstigator(this);

		DeactivateSmoke();

		SmokeRobot.UpdatePlayerInput(FVector::ZeroVector, FVector::ZeroVector);

		TListedActors<AMaxSecurityLaserInvisible> AllLasers;
		for (auto Laser : AllLasers)
		{
			Laser.LaserComp.HideLaser();
		}

		URemoteHackableSmokeRobotEventHandler::Trigger_StopHacked(SmokeRobot);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector Forward = Player.ControlRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		const FVector Right = Player.ControlRotation.RightVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		
		const FVector FwdAcc = Forward * GetAttributeFloat(AttributeNames::MoveForward) * Prison::RemoteHackableSmokeRobot::MaxAcceleration;
		const FVector RightAcc = Right * GetAttributeFloat(AttributeNames::MoveRight) * Prison::RemoteHackableSmokeRobot::MaxAcceleration;

		SmokeRobot.UpdatePlayerInput(FwdAcc, RightAcc);

		if (SmokeAlpha != 1.0)
			SmokeAlpha = Math::FInterpConstantTo(SmokeAlpha, 1.0, DeltaTime, 0.8);

		SmokeRobot.PointLightComp.SetIntensity(SmokeAlpha * 10.0);
		SmokeRobot.HazeSphereComp.SetRelativeScale3D(FVector(SmokeAlpha * 7.5));

		if (bDebug)
			Debug::DrawDebugSphere(Owner.ActorLocation, GetCurrentSmokeRange(), 12, FLinearColor::Purple, 3.0);
		
		// Used by audio systems, needs both start and end of the visualized laser.
		AudioDataComp.LaserInteractions.Reset();

		TListedActors<AMaxSecurityLaserInvisible> AllLasers;
		for (auto Laser : AllLasers)
		{
			FVector StartLoc = Laser.LaserComp.GetBeamStart();
			FVector EndLoc = Laser.LaserComp.GetUnobstructedBeamEnd();
			FLineSphereIntersection Intersection = Math::GetLineSegmentSphereIntersectionPoints(StartLoc, EndLoc, Owner.ActorLocation, GetCurrentSmokeRange());
			if (Intersection.bHasIntersection)
			{
				Laser.LaserComp.ShowLaser();
				if (Laser.GetDistanceTo(Owner) < GetCurrentSmokeRange())
				{
					if (Intersection.IntersectionCount == 1)
						EndLoc = Intersection.MinIntersection;

					Laser.LaserComp.SetBeamStartAndEnd(StartLoc, EndLoc);
					AudioDataComp.LaserInteractions.Add(StartLoc);
					AudioDataComp.LaserInteractions.Add(EndLoc);
				}
				else if (Intersection.IntersectionCount >= 1)
				{
					if (Intersection.IntersectionCount == 2)
					{
						StartLoc = Intersection.MinIntersection;
						EndLoc = Intersection.MaxIntersection;
					}
					else if(Laser.LaserComp.GetBeamStart().Distance(Owner.ActorLocation) < GetCurrentSmokeRange())
					{
						// StartLoc is inside sphere
						EndLoc = Intersection.MinIntersection;
					}
					else
					{
						// StartLoc is outside sphere
						StartLoc = Intersection.MinIntersection;
						EndLoc = Intersection.MinIntersection + Laser.LaserComp.ForwardVector * (Laser.LaserComp.BeamLength - (Intersection.MinIntersection.Distance(Laser.LaserComp.GetBeamStart())));
					}

					AudioDataComp.LaserInteractions.Add(StartLoc);
					AudioDataComp.LaserInteractions.Add(EndLoc);
					Laser.LaserComp.SetBeamStartAndEnd(StartLoc, EndLoc);
				}

				if (bDebug)
				{
					if (Intersection.IntersectionCount == 1)
						Debug::DrawDebugSphere(Intersection.MinIntersection, 25.0, 12, FLinearColor::LucBlue);
					if (Intersection.IntersectionCount == 2)
						Debug::DrawDebugSphere(Intersection.MaxIntersection, 50.0, 12, FLinearColor::Green);
				}
			}
			else if (Laser.LaserComp.GetBeamStart().Distance(Owner.ActorLocation) < GetCurrentSmokeRange())
			{
				Laser.LaserComp.ShowLaser();
				Laser.LaserComp.SetBeamStartAndEnd(StartLoc, EndLoc);

				AudioDataComp.LaserInteractions.Add(Intersection.MinIntersection);
				AudioDataComp.LaserInteractions.Add(EndLoc);
			}
			else
			{
				Laser.LaserComp.HideLaser();
			}
		}
	}

	void ActivateSmoke()
	{
		if (bSmokeActive)
			return;

		bSmokeActive = true;
		SmokeRobot.SmokeComp.Activate(true);
	}

	void DeactivateSmoke()
	{
		if (!bSmokeActive)
			return;

		bSmokeActive = false;
		SmokeRobot.SmokeComp.Deactivate();

		SmokeRobot.PointLightComp.SetIntensity(0.0);
		SmokeRobot.HazeSphereComp.SetRelativeScale3D(FVector(0.0));
	}

	float GetCurrentSmokeRange()
	{
		return Math::Lerp(0.0, MaxSmokeRange, SmokeAlpha);
	}
}