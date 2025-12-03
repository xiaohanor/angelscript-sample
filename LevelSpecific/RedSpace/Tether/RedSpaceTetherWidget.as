UCLASS(Abstract)
class URedSpaceTetherWidget : UHazeUserWidget
{
	ARedSpaceTether TetherActor;

	UPROPERTY(BlueprintReadOnly)
	float DamageAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (TetherActor == nullptr)
			return;
		
		float TargetAlpha = Math::NormalizeToRange(TetherActor.DistanceAlpha, 0.5, 1.0);
		DamageAlpha = Math::FInterpConstantTo(DamageAlpha, TargetAlpha, InDeltaTime, 4.0);
	}
}