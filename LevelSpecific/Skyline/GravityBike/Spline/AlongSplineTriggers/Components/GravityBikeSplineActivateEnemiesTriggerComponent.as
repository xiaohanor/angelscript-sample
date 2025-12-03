class UGravityBikeSplineActivateEnemiesTriggerComponent : UGravityBikeSplineAlongSplineTriggerComponent
{
#if EDITOR
	default EditorColor = FLinearColor::Red;
#endif

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Activate Enemies Trigger")
	bool bDrawArrows = true;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Activate Enemies Trigger|Activate")
	TArray<TSoftObjectPtr<AGravityBikeSplineEnemy>> EnemiesToActivate;

	UPROPERTY(EditInstanceOnly, Category = "Activate Enemies Trigger|Activate")
	bool bSnapSplinePosition = true;

	UPROPERTY(EditInstanceOnly, Category = "Activate Enemies Trigger|Activate")
	bool bSnapSplineSpeed = true;

	UPROPERTY(EditInstanceOnly, Category = "Activate Enemies Trigger|Activate")
	bool bSnapActorTransformToSpline = true;

	UPROPERTY(EditInstanceOnly, Category = "Activate Enemies Trigger|Activate")
	bool bSnapActorVelocity = true;

	UPROPERTY(EditInstanceOnly, Category = "Activate Enemies Trigger|Deactivate")
	TArray<TSoftObjectPtr<AGravityBikeSplineEnemy>> EnemiesToDeactivate;

	void OnActivated() override
	{
		for(auto EnemyToActivate : EnemiesToActivate)
		{
			auto Enemy = EnemyToActivate.Get();
			if(Enemy == nullptr)
				continue;

			auto SplineMoveComp = UGravityBikeSplineEnemyMovementComponent::Get(Enemy);
			if(SplineMoveComp != nullptr)
			{
				if(bSnapSplinePosition)
					SplineMoveComp.SnapSplinePositionToClosestToGravityBike(SplineMoveComp.RespawnOffset);

				if(bSnapSplineSpeed)
					SplineMoveComp.SnapSpeed();

				const FTransform SplineTransform = SplineMoveComp.GetSplineTransform();

				if(bSnapActorTransformToSpline)
					Enemy.SetActorLocationAndRotation(SplineTransform.Location, SplineTransform.Rotation);

				if(bSnapActorVelocity)
					Enemy.SetActorVelocity(SplineTransform.Rotation.ForwardVector * SplineMoveComp.Speed);
			}

			Enemy.ActivateFromActivateEnemiesTrigger(this);
		}

		for(auto EnemyToDeactivate : EnemiesToDeactivate)
		{
			auto Enemy = EnemyToDeactivate.Get();
			if(Enemy == nullptr)
				continue;

			Enemy.Deactivate(Enemy);
		}
	}
};

#if EDITOR
class UGravityBikeSplineActivateEnemiesTriggerComponentVisualizer : UGravityBikeSplineAlongSplineTriggerComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineActivateEnemiesTriggerComponent;

	UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto TriggerComp = Cast<UGravityBikeSplineActivateEnemiesTriggerComponent>(Component);
		if(TriggerComp == nullptr)
			return;

		if(TriggerComp.bDrawArrows)
		{
			for (auto EnemyPtr : TriggerComp.EnemiesToActivate)
			{
				AGravityBikeSplineEnemy Enemy = EnemyPtr.Get();

				if(Enemy == nullptr)
					continue;

				DrawArrow(TriggerComp.WorldLocation, Enemy.ActorLocation, FLinearColor::Red, 300.0, 50.0);

				if(Editor::IsComponentSelected(TriggerComp))
					DrawWorldString(f"Activate {Enemy.GetActorNameOrLabel()}", Enemy.ActorLocation, FLinearColor::Red, bCenterText = true);
			}

			for (auto EnemyPtr : TriggerComp.EnemiesToDeactivate)
			{
				AGravityBikeSplineEnemy Enemy = EnemyPtr.Get();

				if(Enemy == nullptr)
					continue;

				DrawArrow(TriggerComp.WorldLocation, Enemy.ActorLocation, FLinearColor::Yellow, 300.0, 50.0);

				if(Editor::IsComponentSelected(TriggerComp))
					DrawWorldString(f"Deactivate {Enemy.GetActorNameOrLabel()}", Enemy.ActorLocation, FLinearColor::Yellow, bCenterText = true);
			}
		}
	}
}
#endif