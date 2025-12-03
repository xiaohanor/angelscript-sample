event void FRemoteHackableToiletEvent();

UCLASS(Abstract)
class ARemoteHackableToilet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ToiletRoot;

	UPROPERTY(DefaultComponent, Attach = ToiletRoot)
	UStaticMeshComponent ToiletMesh;

	UPROPERTY(DefaultComponent, Attach = ToiletRoot)
	USceneComponent FlushRoot;

	UPROPERTY(DefaultComponent, Attach = ToiletRoot)
	URemoteHackingResponseComponent HackingComp;

	UPROPERTY(DefaultComponent, Attach = HackingComp)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableToiletCapability");

	UPROPERTY(EditInstanceOnly)
	AActor PipeSplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	FRemoteHackingEvent OnHackLaunchStarted;

	UPROPERTY()
	FRemoteHackingEvent OnReachedEnd;

	UPROPERTY()
	FRemoteHackingEvent OnHackStopped;

	UPROPERTY()
	FRemoteHackableToiletEvent OnStartFlushing;

	UPROPERTY()
	FRemoteHackableToiletEvent OnStopFlushing;

	UPROPERTY(EditDefaultsOnly)
	FText FlushText;

	float SplineDist = 0.0;
	float SplineSpeed = 1000.0;

	bool bPlayerReachedToilet = false;

	bool bFlushing = false;
	FHazeAcceleratedFloat FlushRate;
	float MaxFlushSpeed = 800.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		if (PipeSplineActor != nullptr)
		{
			SplineComp = UHazeSplineComponent::Get(PipeSplineActor);
			HackingComp.SetWorldLocationAndRotation(SplineComp.GetWorldLocationAtSplineFraction(0.0), SplineComp.GetWorldRotationAtSplineFraction(0.0));
		}

		HackingComp.OnLaunchStarted.AddUFunction(this, n"HackLaunchStarted");
		HackingComp.OnHackingStopped.AddUFunction(this, n"HackingStopped");
	}

	UFUNCTION()
	private void HackLaunchStarted(FRemoteHackingLaunchEventParams LaunchParams)
	{
		URemoteHackableToiletEventhandler::Trigger_StartHacking(this);
		
		OnHackLaunchStarted.Broadcast();
	}

	UFUNCTION()
	private void HackingStopped()
	{
		HackingComp.SetHackingAllowed(false);

		URemoteHackableToiletEventhandler::Trigger_StopHacking(this);

		OnHackStopped.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HackingComp.bHacked && !bPlayerReachedToilet)
		{
			SplineDist += SplineSpeed * DeltaTime;
			FVector Loc = SplineComp.GetWorldLocationAtSplineDistance(SplineDist);
			FRotator Rot = SplineComp.GetWorldRotationAtSplineDistance(SplineDist).Rotator();
			HackingComp.SetWorldLocationAndRotation(Loc, Rot);

			if (SplineDist >= SplineComp.SplineLength)
			{
				HackingComp.UpdateCancelableStatus(true);
				bPlayerReachedToilet = true;
				OnReachedEnd.Broadcast();
			}
		}

		if (bFlushing)
			FlushRate.AccelerateTo(MaxFlushSpeed, 2.0, DeltaTime);
		else
			FlushRate.AccelerateTo(0.0, 1.0, DeltaTime);

		FlushRoot.AddLocalRotation(FRotator(0.0, FlushRate.Value * DeltaTime, 0.0));
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartFlushing()
	{
		bFlushing = true;
		BP_StartFlushing();

		URemoteHackableToiletEventhandler::Trigger_StartFlushing(this);

		OnStartFlushing.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartFlushing() {}

	UFUNCTION(CrumbFunction)
	void CrumbStopFlushing()
	{
		bFlushing = false;
		BP_StopFlushing();

		URemoteHackableToiletEventhandler::Trigger_StopFlushing(this);

		OnStopFlushing.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StopFlushing() {}
}

class URemoteHackableToiletCapability : URemoteHackableBaseCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	ARemoteHackableToilet Toilet;
	bool bPlayerReachedToilet = false;

	float TimeSpentFlushing = 0.0;
	bool bFlushTutorialCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Toilet = Cast<ARemoteHackableToilet>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
		Player.RemoveCancelPromptByInstigator(this);

		if (HasControl())
		{
			if (Toilet.bFlushing)
				Toilet.CrumbStopFlushing();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bPlayerReachedToilet)
		{
			if (Toilet.bPlayerReachedToilet)
			{
				bPlayerReachedToilet = true;
				FTutorialPrompt FlushPrompt;
				FlushPrompt.Action = ActionNames::PrimaryLevelAbility;
				FlushPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
				FlushPrompt.Text = Toilet.FlushText;
				Player.ShowTutorialPromptWorldSpace(FlushPrompt, this, Toilet.FlushRoot, FVector::ZeroVector, 0.0);

				Player.ShowCancelPrompt(this);
			}

			return;
		}

		if (HasControl())
		{
			if (IsActioning(ActionNames::PrimaryLevelAbility))
			{
				if (!Toilet.bFlushing)
					Toilet.CrumbStartFlushing();

				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * 30) * 0.2;
				FF.RightMotor = Math::Sin(-ActiveDuration * 30) * 0.2;
				Player.SetFrameForceFeedback(FF);

				TimeSpentFlushing += DeltaTime;
				if (!bFlushTutorialCompleted && TimeSpentFlushing >= 0.75)
				{
					bFlushTutorialCompleted = true;
					Player.RemoveTutorialPromptByInstigator(this);
				}
			}
			else
			{
				if (Toilet.bFlushing)
					Toilet.CrumbStopFlushing();
			}
		}
	}
}

UCLASS(Abstract)
class URemoteHackableToiletEventhandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFlushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopFlushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartHacking() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopHacking() {}
}