event void FIslandShootableBoxEvent(AIslandShootableBox ExplodedBarrel);

class AIslandShootableBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BoxMesh;

	bool bIsExploded;

	UPROPERTY()
	FIslandShootableBoxEvent OnExploded;

	UPROPERTY(DefaultComponent, Attach = BoxMesh)
	UIslandRedBlueImpactCounterResponseComponent RedBlueTargetComponent;

	UPROPERTY()
	UForceFeedbackEffect ShotFeedback;

	AHazePlayerCharacter LastPlayerImpacter;

	UPROPERTY()
	UNiagaraSystem Effect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RedBlueTargetComponent.OnImpactEvent.AddUFunction(this, n"BulletImpact");
	}

	UFUNCTION()
	void BulletImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (bIsExploded)
			return;

		LastPlayerImpacter = Data.Player;


		ExplodeBox();
	}

	UFUNCTION()
	void ExplodeBox()
	{
		if (bIsExploded)
			return;

		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(Effect, ActorCenterLocation);
		OnExploded.Broadcast(this);
		LastPlayerImpacter.PlayForceFeedback(ShotFeedback, false, false, this);
		UIslandShootableBoxEventHandler::Trigger_OnExploded(this);
		bIsExploded = true;
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_BoxExploded()
	{
	}

};

UCLASS(Abstract)
class UIslandShootableBoxEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExploded() {}

};