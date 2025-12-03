UCLASS(Abstract)
class USanctuaryCentipedeBreakableEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreak() {}
}

class ASanctuaryCentipedeBreakable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCentipedeBiteResponseComponent BiteResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;
	default DisableComponent.SetEnableAutoDisable(true);

	UPROPERTY()
	UNiagaraSystem VFXSystem;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Targetable")
	EHazeSelectPlayer UsableByPlayers = EHazeSelectPlayer::Both;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BiteResponseComp.OnCentipedeBiteStarted.AddUFunction(this, n"HandleBiteStarted");
		BiteResponseComp.SetUsableByPlayers(UsableByPlayers);
	}

	UFUNCTION()
	private void HandleBiteStarted(FCentipedeBiteEventParams BiteParams)
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(VFXSystem, BiteResponseComp.WorldLocation);

		USanctuaryCentipedeBreakableEventHandler::Trigger_OnBreak(this);

		// Disable
		BiteResponseComp.Disable(this);
		AddActorDisable(this);
	}
};