event void FOnShellInteractedByBoth();

class UBattlefieldCruiserGrabShellVisualizerComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UBattlefieldCruiserGrabShellVisualizerDudComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto Shell = Cast<ABattleCruiserGrabOnShell>(Component.Owner);

		if (Shell == nullptr)
			return;

		FVector End = Shell.ActorLocation + Shell.ActorForwardVector * 550000.0;
		// DrawArrow(Shell.ActorLocation, End, FLinearColor::Green, 250, 175);
	}
}

class UBattlefieldCruiserGrabShellVisualizerDudComponent : UActorComponent
{

}

class ABattleCruiserGrabOnShell : AHazeActor
{
	default SetTickGroup(ETickingGroup::TG_HazeGameplay);

	UPROPERTY()
	FOnShellInteractedByBoth OnShellInteractedByBoth;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ExplosionSpawnLoc;

	UPROPERTY(DefaultComponent, Attach = Root)
	UThreeShotInteractionComponent InteractCompMio;
	default InteractCompMio.UsableByPlayers = EHazeSelectPlayer::Mio;
	default InteractCompMio.bPlayerCanCancelInteraction = false; 
	UPROPERTY(DefaultComponent, Attach = Root)
	UThreeShotInteractionComponent InteractCompZoe;
	default InteractCompZoe.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractCompZoe.bPlayerCanCancelInteraction = false; 

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BattleCruiserGrabOnShellCapability");

	UPROPERTY(DefaultComponent)
	UBattlefieldCruiserGrabShellVisualizerDudComponent DudVisualizeComp;

	UPROPERTY()
	UNiagaraSystem ChargeExplosion;

	float TargetSpeed = 25000.0;
	float LeaveTargetSpeed = 1070000.0;
	float TimeDilation = 1.0;
	float TargetTimeDilation = 0.075;

	bool bShellActive;
	bool bTimeDilationActive;
	bool bSetTimeDilation;

	int Uses;
	bool bNotUsed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractCompMio.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractCompZoe.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractCompMio.Disable(this);
		InteractCompZoe.Disable(this);
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		Uses++;

		if (Uses >= 2 && !bNotUsed)
		{
			bNotUsed = true;
			OnShellInteractedByBoth.Broadcast();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bTimeDilationActive)
		{
			TimeDilation = Math::FInterpConstantTo(TimeDilation, TargetTimeDilation, DeltaSeconds, 1.0);
			Time::SetWorldTimeDilation(TimeDilation);
		}
		else if (!bTimeDilationActive && TimeDilation < 1.0)
		{
			TimeDilation = Math::FInterpConstantTo(TimeDilation, 1.0, DeltaSeconds, 1.0);
			Time::SetWorldTimeDilation(TimeDilation);
		}
		else
		{
			if (bSetTimeDilation)
			{
				bSetTimeDilation = false;
				Time::SetWorldTimeDilation(TimeDilation);
			}
		}
	}

	UFUNCTION()
	void ActivateShell()
	{
		bShellActive = true;
		InteractCompMio.Enable(this);
		InteractCompZoe.Enable(this);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ChargeExplosion, ExplosionSpawnLoc.WorldLocation);
	}

	UFUNCTION()
	void ActivateTimeDilation()
	{
		bTimeDilationActive = true;
		bSetTimeDilation = true;
		TimeDilation = 1.0;
	}

	UFUNCTION()
	void DeactivateTimeDilation()
	{
		bTimeDilationActive = false;
		TargetSpeed = LeaveTargetSpeed;
	}
}