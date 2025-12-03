UCLASS(Abstract)
class AGameShowArenaSpinningFlameThrower : AGameShowArenaDynamicObstacleBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FXRoot;

	UPROPERTY(DefaultComponent, Attach = FXRoot)
	UNiagaraComponent FX01;

	UPROPERTY(DefaultComponent, Attach = FXRoot)
	UNiagaraComponent FX02;

	UPROPERTY(DefaultComponent, Attach = FXRoot)
	UNiagaraComponent FX03;

	UPROPERTY(DefaultComponent, Attach = FXRoot)
	UNiagaraComponent FX04;

	UPROPERTY(DefaultComponent, Attach = FXRoot)
	UBoxComponent Collision01;

	UPROPERTY(DefaultComponent, Attach = FXRoot)
	UBoxComponent Collision02;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY(EditInstanceOnly)
	float RotationSpeed = 20;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UGameShowArenaSpinningFlameThrowerVisualizerComponent VisualizerComp;
#endif
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision01.OnComponentBeginOverlap.AddUFunction(this, n"OnFlameThrowerOverlap");
		Collision02.OnComponentBeginOverlap.AddUFunction(this, n"OnFlameThrowerOverlap");
	}

	UFUNCTION()
	private void OnFlameThrowerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
							   UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
							   const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Player.KillPlayer();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FRotator RotToAdd = FRotator(0, RotationSpeed * DeltaSeconds, 0);
		FXRoot.AddLocalRotation(RotToAdd);
	}
};

#if EDITOR
class UGameShowArenaSpinningFlameThrowerVisualizerComponent : UActorComponent
{
}

class UGameShowArenaSpinningFlameThrowerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGameShowArenaSpinningFlameThrowerVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UGameShowArenaSpinningFlameThrowerVisualizerComponent>(Component);
		if (Comp == nullptr)
			return;

		if (Comp.Owner.IsTemporarilyHiddenInEditor())
			return;

		auto FlameThrower = Cast<AGameShowArenaSpinningFlameThrower>(Comp.Owner);
		FRotator NewRotation1 = FlameThrower.Collision01.WorldRotation + FRotator(0,  FlameThrower.RotationSpeed * Time::GameTimeSeconds, 0);
		FRotator NewRotation2 = FlameThrower.Collision02.WorldRotation + FRotator(0, FlameThrower.RotationSpeed * Time::GameTimeSeconds, 0);

		DrawWireShape(FlameThrower.Collision01.GetCollisionShape(), FlameThrower.ActorLocation, NewRotation1.Quaternion(), FLinearColor::DPink, 5, true);
		DrawWireShape(FlameThrower.Collision02.GetCollisionShape(), FlameThrower.ActorLocation, NewRotation2.Quaternion(), FLinearColor::DPink, 5, true);
	}
}

#endif