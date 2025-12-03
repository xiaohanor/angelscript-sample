event void FArenaLaunchPadEvent(FArenaLaunchPadParams Params);
event void FArenaLaunchPadDisabledEvent(AArenaLaunchPad LaunchPad);

UCLASS(Abstract)
class AArenaLaunchPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LaunchPadRoot;

	UPROPERTY(DefaultComponent, Attach = LaunchPadRoot)
	UStaticMeshComponent LaunchPadFrameMesh;

	UPROPERTY(DefaultComponent, Attach = LaunchPadRoot)
	UFauxPhysicsTranslateComponent SpringRoot;

	UPROPERTY(DefaultComponent, Attach = SpringRoot)
	UStaticMeshComponent LaunchPadMesh;

	UPROPERTY(DefaultComponent, Attach = LaunchPadRoot)
	USceneComponent LidRoot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenLidTimeLike;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EnabledMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface DisabledMaterial;

	UPROPERTY()
	FArenaLaunchPadDisabledEvent OnDisabled;

	UPROPERTY()
	FArenaLaunchPadEvent OnPlayerLaunched;

	TArray<UStaticMeshComponent> LidMeshes;

	bool bEnabled = false;

	UPROPERTY(EditAnywhere)
	bool bAlwaysActive = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> LaunchCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LaunchForceFeedback;

	bool bForceDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LidRoot.GetChildrenComponentsByClass(UStaticMeshComponent, true, LidMeshes);

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");

		OpenLidTimeLike.BindUpdate(this, n"UpdateOpenLid");
		OpenLidTimeLike.BindFinished(this, n"FinishOpenLid");

		SpringRoot.SetRelativeLocation(FVector(0.0, 0.0, -15.0));

		if (bAlwaysActive)
			Enable();

		LaunchPadFrameMesh.SetMaterial(0, DisabledMaterial);
	}

	UFUNCTION()
	void Enable()
	{
		if (bEnabled)
			return;

		bEnabled = true;
		bForceDisabled = false;
		OpenLidTimeLike.Play();
		Timer::SetTimer(this, n"RevealPad", 0.2);

		LaunchPadFrameMesh.SetMaterial(0, EnabledMaterial);
	}

	UFUNCTION(NotBlueprintCallable)
	void RevealPad()
	{
		SpringRoot.ApplyImpulse(SpringRoot.WorldLocation, FVector::UpVector * 100.0);
	}

	UFUNCTION()
	void Disable()
	{
		if (!bEnabled)
			return;

		bEnabled = false;
		OpenLidTimeLike.Reverse();

		LaunchPadFrameMesh.SetMaterial(0, DisabledMaterial);
	}

	void ForceDisable()
	{
		bForceDisabled = true;
		Disable();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenLid(float CurValue)
	{
		for (UStaticMeshComponent MeshComp : LidMeshes)
		{
			FVector Loc = Math::Lerp(FVector::ZeroVector, -MeshComp.RelativeRotation.RightVector * 100.0, CurValue);
			MeshComp.SetRelativeLocation(Loc);
		}

		float Rot = Math::Lerp(0.0, 180.0, CurValue);
		LidRoot.SetRelativeRotation(FRotator(0.0, Rot, 0.0));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishOpenLid()
	{
		if (!bEnabled)
			OnDisabled.Broadcast(this);
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		if (!bEnabled)
			return;

		FArenaLaunchPadParams Params;
		Params.Player = Player;
		OnPlayerLaunched.Broadcast(Params);

		Player.AddPlayerLaunchImpulseToReachHeight(2000.0);
		Player.PlayCameraShake(LaunchCamShake, this);
		Player.PlayForceFeedback(LaunchForceFeedback, false, true, this);

		BP_LaunchPlayer();

		Disable();

		if (HasControl())
		{
			TArray<AArenaLaunchPad> Pads = GetAllLaunchPads();
			Pads.Remove(this);

			TArray<AArenaLaunchPad> ValidPads;
			for (AArenaLaunchPad Pad : Pads)
			{
				if (!Pad.bEnabled)
					ValidPads.Add(Pad);
			}

			ValidPads.Shuffle();

			NetEnableNewLaunchPad(ValidPads[0]);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchPlayer() {}

	UFUNCTION(NetFunction)
	void NetEnableNewLaunchPad(AArenaLaunchPad Pad)
	{
		if (!bForceDisabled)
			Pad.Enable();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bEnabled)
			SpringRoot.ApplyForce(SpringRoot.WorldLocation, -FVector::UpVector * 500.0);
	}

	TArray<AArenaLaunchPad> GetAllLaunchPads()
	{
		TListedActors<AArenaLaunchPad> LaunchPads;
		return LaunchPads.GetArray();
	}
}

struct FArenaLaunchPadParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}