class UDanceShowdownPlayerFaceMonkeyCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);

	default TickGroup = EHazeTickGroup::Movement;

	UDanceShowdownPlayerComponent DanceComp;
	FVector2D LastExtreme;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DanceComp = UDanceShowdownPlayerComponent::Get(Player);
		DanceShowdown::AutoShakeMonkey.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DanceShowdown::GetManager().IsActive())
			return false;

		if(DanceComp.MonkeyOnFace == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DanceShowdown::GetManager().IsActive())
			return true;

		if(DanceComp.MonkeyOnFace == nullptr)
			return true;


		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FStickWiggleSettings Settings;
		Settings.bAllowPlayerCancel = false;
		Settings.bShowStickSpinWidget = true;
		Settings.bBlockOtherGameplay = true;
		Settings.bChunkProgress = true;
		Settings.WiggleStartDecreasingDelay = 1;
		Settings.HorizontalWiggleThreshold = 0.7;
		Settings.WidgetAttachComponent = Player.RootComponent;

		Settings.WidgetPositionOffset = DanceComp.FaceMonkeyWidgetOffset[Player];
		Player.StartStickWiggle(Settings, this);
		//Player.PlayForceFeedback(DanceComp.MonkeyOnFaceForceFeedback, true, true, this);
		Game::Mio.PlayCameraShake(DanceComp.MonkeyOnFaceCameraShake, this);
		FDanceShowdownPlayerEventData Data;
		Data.Player = Player;
		UDanceShowdownPlayerEventHandler::Trigger_OnStartMonkeyOnHead(DanceComp.GetPlayerShapeshiftActor(), Data);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopStickWiggle(this);
		//Player.StopForceFeedback(this);
		Game::Mio.StopCameraShakeByInstigator(this);
		Player.PlayForceFeedback(ForceFeedback::Default_Medium, this);
		FDanceShowdownPlayerEventData Data;
		Data.Player = Player;
		UDanceShowdownPlayerEventHandler::Trigger_OnStopMonkeyOnHead(DanceComp.GetPlayerShapeshiftActor(), Data);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector2D RawMoveInput2D = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			DanceComp.SetStickWiggleInput(FVector2D(RawMoveInput2D.Y, -RawMoveInput2D.X));


			if(Player.GetStickWiggleState(this).IsFinished() || (DanceShowdown::AutoShakeMonkey.IsEnabled() && ActiveDuration > 1))
			{
				DanceComp.MonkeyOnFace.NetFlingMonkey(Player.IsMio() ? -1 : 1, Time::RealTimeSeconds);
			}
			else
			{
				DanceComp.MonkeyOnFace.Wiggle(Player.GetStickWiggleState(this).WiggleInput);
			}
		}

		if(Player.Mesh.CanRequestLocomotion())
		{
			Player.Mesh.RequestLocomotion(n"DanceShowdown", this);
		}
	}
};