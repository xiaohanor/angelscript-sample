struct FAnnoyedByGnatParams
{
	UTundraGnatComponent GnatComp;
}

class UTundraGnatPlayerAnnoyedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"AnnoyedByGnat");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	UTundraGnapeAnnoyedPlayerComponent GnapeAnnoyedComp;
	UPlayerMovementComponent MoveComp;
	UTundraGnatComponent GnatComp;
	UTundraWalkingStickContainerComponent WalkingStickContainer;
	UTundraGnatSettings GnatSettings;
	UTundraPlayerTreeGuardianSettings Settings;
	USteppingMovementData Movement;
	FVector InitialLocalLoc;
	float MaxPushedDistance = 100.0;

	bool bActiveButtonMash = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GnapeAnnoyedComp = UTundraGnapeAnnoyedPlayerComponent::GetOrCreate(Player);	
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player); 
		Movement = MoveComp.SetupSteppingMovementData();
		WalkingStickContainer = UTundraWalkingStickContainerComponent::GetOrCreate(Game::Mio);

		DevTogglesGnape::ZoeIgnoreGnapes.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAnnoyedByGnatParams& OutParams) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;
		if (GnapeAnnoyedComp.AnnoyingGnapes.Num() == 0)
			return false;
		if (DevTogglesGnape::ZoeIgnoreGnapes.IsEnabled())
			return false;
		OutParams.GnatComp = GnapeAnnoyedComp.AnnoyingGnapes[0];
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		if (GnapeAnnoyedComp.AnnoyingGnapes.Num() == 0)
			return true;
		if (DevTogglesGnape::ZoeIgnoreGnapes.IsEnabled())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAnnoyedByGnatParams Params)
	{
		GnatComp = Params.GnatComp;
		GnatSettings = UTundraGnatSettings::GetSettings(Cast<AHazeActor>(GnatComp.Owner)); 
		bActiveButtonMash = false;

		// Remain in place on host and stop any lifegiving
		if (GnatComp.Host != nullptr)
		{
			USceneComponent BodyComp = UTundraGnatHostComponent::Get(GnatComp.Host);
			if (GnatComp.HostBody != nullptr)
				BodyComp = GnatComp.HostBody;
			MoveComp.FollowComponentMovement(BodyComp, this, EMovementFollowComponentType::ResolveCollision, EInstigatePriority::High);
			if (Player.IsAnyCapabilityActive(TundraShapeshiftingTags::TundraLifeGiving))
			{
				MaxPushedDistance = 1.0;
				FVector InteractLoc = Player.ActorLocation;
				auto WalkingStick = Cast<ATundraWalkingStick>(GnatComp.Host);
				if ((WalkingStick != nullptr) && (WalkingStick.LifeGivingActorRef != nullptr))
					InteractLoc += (WalkingStick.LifeGivingActorRef.ActorLocation - InteractLoc).GetSafeNormal() * 5.0;
				InitialLocalLoc = BodyComp.WorldTransform.InverseTransformPositionNoScale(InteractLoc);
			}
			else
			{
				MaxPushedDistance = 100.0;
				InitialLocalLoc = BodyComp.WorldTransform.InverseTransformPositionNoScale(Player.ActorLocation);
			}
		}

		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(TundraShapeshiftingTags::TundraLifeGiving, this);
		Player.BlockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);

		if(Player.IsZoe() && WalkingStickContainer.WalkingStick.CurrentState != ETundraWalkingStickState::None)
			Player.ActivateCameraCustomBlend(WalkingStickContainer.WalkingStick.EntAttackedCam, TundraWalkingStickBlendAsset, WalkingStickContainer.WalkingStick.TreeAttackedBlendDuration, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::TundraLifeGiving, this);
		Player.UnblockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		MoveComp.UnFollowComponentMovement(this);
		GnatComp = nullptr; // In case a OnButtonMashCompleted is received after this
		Player.StopButtonMash(this); // In case gnats were removed by outside sources, such as squashing by monkey

		if(WalkingStickContainer.WalkingStick != nullptr && Player.IsZoe() && WalkingStickContainer.WalkingStick.CurrentState != ETundraWalkingStickState::None)
		{
			Player.DeactivateCameraCustomBlend(WalkingStickContainer.WalkingStick.EntAttackedCam, TundraWalkingStickBlendAsset, WalkingStickContainer.WalkingStick.TreeAttackedBlendDuration);
			WalkingStickContainer.WalkingStick.LifeGivingActorRef.LifeReceivingComp.ForceEnterLifeGivingInteraction();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bActiveButtonMash && GnatSettings.bShakeOffWithButtonMash)
		{
			// Buttonmash to shake the next annoying little blighter off!
			FButtonMashSettings Mash;
			Mash.Duration = GnatSettings.ShakeOffButtonMashDuration;
			Mash.Difficulty = GnatSettings.ShakeOffButtonMashDifficulty;
			Player.StartButtonMash(Mash, this, FOnButtonMashCompleted(this, n"OnButtonMashCompleted"));
			bActiveButtonMash = true;
			GnatComp = GnapeAnnoyedComp.AnnoyingGnapes[0]; // The effects of this is synced by gnat itself.
		}

		// Slow to a stop and fall if in air
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float Friction = MoveComp.HasGroundContact() ? Settings.HorizontalGroundFriction : Settings.HorizontalAirFriction;
				FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
				if (GnatComp.HostBody != nullptr)
				{
					// Hack to avoid tree guardian drifting away from initial location (from movement system following bug?)
					FVector InitialLoc = GnatComp.HostBody.WorldTransform.TransformPositionNoScale(InitialLocalLoc);
					if (!Player.ActorLocation.IsWithinDist2D(InitialLoc, MaxPushedDistance))
						HorizontalVelocity += (InitialLoc - Player.ActorLocation).GetSafeNormal2D() * 20.0;
				}
				HorizontalVelocity *= Math::Pow(Math::Exp(-Friction), DeltaTime);
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				Movement.AddVerticalVelocity(MoveComp.VerticalVelocity);
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();
			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}

			if(!MoveComp.HasGroundContact())
				Movement.RequestFallingForThisFrame();

			FName FeatureTag = FeatureGnatReactions::GnatReactions;		
			if (MoveComp.IsInAir())
				FeatureTag = n"AirMovement";
			else if (MoveComp.HasGroundContact() && MoveComp.WasFalling())
				FeatureTag = n"Landing";
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, FeatureTag);
		}
	}

	UFUNCTION()
	private void OnButtonMashCompleted()
	{
		bActiveButtonMash  = false;
		GnapeAnnoyedComp.AnnoyingGnapes.RemoveSingleSwap(GnatComp);
		GnatComp.bShakenOff = true;
	}
}


