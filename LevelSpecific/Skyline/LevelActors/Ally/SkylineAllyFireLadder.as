UCLASS(Abstract)
class USkylineAllyFireLadderEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}
}

class ASkylineAllyFireLadder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LadderPivot1;

	UPROPERTY(DefaultComponent, Attach = LadderPivot1)
	USceneComponent LadderPivot2;

	UPROPERTY(DefaultComponent, Attach = LadderPivot2)
	USceneComponent LadderPivot3;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LadderLockMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(EditInstanceOnly)
	ALadder LadderMio;

	UPROPERTY(EditInstanceOnly)
	ALadder LadderZoe;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		ExtendLadder();
	}

	UFUNCTION()
	void ExtendLadder()
	{
		BPExtendLadder();
		Timer::SetTimer(this, n"EnableLadders", 0.5);
		
		LadderLockMeshComp.SetHiddenInGame(true, true);
		GravityBladeResponseComponent.AddResponseComponentDisable(this);

		USkylineAllyFireLadderEventHandler::Trigger_OnHit(this);
	}

	UFUNCTION()
	private void EnableLadders()
	{
		LadderMio.EnableAfterStartDisabled();
		LadderZoe.EnableAfterStartDisabled();
	}

	UFUNCTION(BlueprintEvent)
	void BPExtendLadder()
	{
	}
};