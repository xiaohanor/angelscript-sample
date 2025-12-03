UCLASS(Abstract)
class AHayStack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HayRoot;

	UPROPERTY(DefaultComponent, Attach = HayRoot)
	USphereComponent OverlapTrigger;

	UPROPERTY(DefaultComponent, Attach = HayRoot)
	USceneComponent PlayerLocationComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeConstrainedPhysicsValue JiggleValue;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect EnterFF;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverlapTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
	}

	UFUNCTION(NotBlueprintCallable)
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor,  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player.HasControl())
			CrumbEnteredByPlayer(Player);
	}

	UFUNCTION(CrumbFunction)
	void CrumbEnteredByPlayer(AHazePlayerCharacter Player)
	{
		BP_Enter();

		UHayStackPlayerComponent HayStackComp = UHayStackPlayerComponent::Get(Player);
		if (HayStackComp != nullptr)
		{
			HayStackComp.CurrentHayStack = this;
		}

		JiggleValue.AddImpulse(-0.35);

		FHayStackEffectEventParams Params;
		Params.Player = Player;
		if (Player.IsAnyCapabilityActive(n"HayStackDive"))
			UHayStackEffectEventHandler::Trigger_PlayerLanded(this, Params);
		else
		{
			Player.PlayForceFeedback(EnterFF, false, true, this);
			UHayStackEffectEventHandler::Trigger_PlayerEntered(this, Params);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Enter() {}

	void Exit(AHazePlayerCharacter Player)
	{
		JiggleValue.AddImpulse(0.35);
		BP_Exit();

		Player.PlayForceFeedback(EnterFF, false, true, this);

		FHayStackEffectEventParams Params;
		Params.Player = Player;
		UHayStackEffectEventHandler::Trigger_PlayerLeft(this, Params);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Exit() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		JiggleValue.SpringTowards(1.0, 400.0);
		JiggleValue.Update(DeltaTime);
		HayRoot.SetRelativeScale3D(FVector(1.0, 1.0, JiggleValue.Value));
	}

	UFUNCTION()
	void StartDive(AHazePlayerCharacter Player, FVector Loc, float Yaw)
	{
		UHayStackPlayerComponent HayStackComp = UHayStackPlayerComponent::Get(Player);
		HayStackComp.StartDive(Loc, Yaw);
	}
}

struct FHayStackEffectEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

class UHayStackEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void PlayerLanded(FHayStackEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void PlayerEntered(FHayStackEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void PlayerLeft(FHayStackEffectEventParams Params) {}
}