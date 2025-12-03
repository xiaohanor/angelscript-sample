event void FASummitEggChaseScrambleWallLeftSignature();

class ASummitEggChaseScrambleWallLeft : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UNiagaraSystem ExplosionEffect;

	UPROPERTY()
	FASummitEggChaseScrambleWallLeftSignature OnExploded;

	UPROPERTY()
	FVector WorldPosition;

	bool bAutoDisable;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WorldPosition = Root.GetWorldLocation();
	}

	UFUNCTION()
	void ExplodeWall()
	{
		UASummitEggChaseScrambleWallLeftEventHandler::Trigger_OnExploded(this);
		OnExploded.Broadcast();
		BP_HandleOnExploded();

		if (CameraShake == nullptr)
			return;

		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandleOnExploded(){}

};

UCLASS(Abstract)
class UASummitEggChaseScrambleWallLeftEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExploded() {}
}