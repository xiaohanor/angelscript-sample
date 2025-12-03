UCLASS(Abstract)
class ARemoteHackableCellDoorPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	URemoteHackingResponseComponent HackingComp;

	UPROPERTY(DefaultComponent)
	URemoteHackingResponseAudioComponent HackingAudioComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableCellDoorCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedDoorRotComp;

	UPROPERTY(EditInstanceOnly)
	ARemoteHackableCellDoor Door;

	UPROPERTY(EditDefaultsOnly)
	FText OpenDoorText;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!HackingComp.IsHacked())
		{
			Door.RotateComp.ApplyAngularForce(10.0);
		}
	}
}

UCLASS(Abstract)
class ARemoteHackableCellDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TutorialAttachComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedDoorRotComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect CloseFF;

	bool bFullyClosed = true;
	bool bFullyOpened = true;

	bool bPlayerOpening = false;
	bool bMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		RotateComp.OnMinConstraintHit.AddUFunction(this, n"FullyOpened");
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"FullyClosed");
	}

	UFUNCTION()
	private void FullyOpened(float Strength)
	{
		URemoteHackableCellDoorEffectEventhandler::Trigger_StopMoving(this);
		URemoteHackableCellDoorEffectEventhandler::Trigger_FullyOpen(this);

		bFullyOpened = true;

		Game::Mio.PlayForceFeedback(CloseFF, false, true, this);
	}

	UFUNCTION()
	private void FullyClosed(float Strength)
	{
		URemoteHackableCellDoorEffectEventhandler::Trigger_StopMoving(this);
		URemoteHackableCellDoorEffectEventhandler::Trigger_FullyClosed(this);

		bFullyClosed = true;

		Game::Mio.PlayForceFeedback(CloseFF, false, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bPlayerOpening)
		{
			if (bFullyClosed)
			{
				URemoteHackableCellDoorEffectEventhandler::Trigger_StartMoving(this);
				bFullyClosed = false;
			}
		}
		else
		{
			if (bFullyOpened)
			{
				URemoteHackableCellDoorEffectEventhandler::Trigger_StartMoving(this);
				bFullyOpened = false;
			}

			RotateComp.ApplyAngularForce(0.5);
		}
	}
}

class URemoteHackableCellDoorCapability : URemoteHackableBaseCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	ARemoteHackableCellDoorPanel DoorPanel;

	float TimeSpentOpening = 0.0;
	bool bTutorialCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		DoorPanel = Cast<ARemoteHackableCellDoorPanel>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		TutorialPrompt.Text = DoorPanel.OpenDoorText;
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, DoorPanel.Door.TutorialAttachComp, FVector::ZeroVector, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);

		DoorPanel.Door.bPlayerOpening = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsActioning(ActionNames::PrimaryLevelAbility))
		{
			DoorPanel.Door.RotateComp.ApplyAngularForce(-8.0);

			DoorPanel.Door.bPlayerOpening = true;

			if (!Math::IsNearlyEqual(DoorPanel.Door.RotateComp.RelativeRotation.Pitch, 90.0, 1.0))
			{
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * 20) * 0.5;
				FF.RightMotor = Math::Sin(-ActiveDuration * 20) * 0.5;
				Player.SetFrameForceFeedback(FF);
			}

			if (!bTutorialCompleted)
			{
				TimeSpentOpening += DeltaTime;
				if (TimeSpentOpening >= 0.5)
				{
					bTutorialCompleted = true;
					Player.RemoveTutorialPromptByInstigator(this);
				}
			}
		}
		else
		{
			DoorPanel.Door.bPlayerOpening = false;
		}
	}
}

UCLASS(Abstract)
class URemoteHackableCellDoorEffectEventhandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FullyOpen() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FullyClosed() {}
}