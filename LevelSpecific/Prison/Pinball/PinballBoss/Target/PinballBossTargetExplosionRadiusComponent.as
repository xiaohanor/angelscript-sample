UCLASS(NotBlueprintable)
class UPinballBossTargetExplosionRadiusComponent : USceneComponent
{
	/**
	 * Radius of the overlap in 2D
	 * The MagnetDrone radius will be added on this when overlap checking, meaning that if the magnet drone touches
	 * this radius, we are overlapping.
	 */
	UPROPERTY(EditAnywhere)
	float Radius;

	bool IsOverlappingPlayer(const AHazePlayerCharacter Player) const
	{
		const FVector LocationOnPlane = WorldLocation.VectorPlaneProject(FVector::ForwardVector);
		const FVector PlayerLocationOnPlane = Player.ActorCenterLocation.VectorPlaneProject(FVector::ForwardVector);
		return LocationOnPlane.Distance(PlayerLocationOnPlane) < (Radius + MagnetDrone::Radius);
	}
};

#if EDITOR
class UPinballBossTargetExplosionRadiusComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPinballBossTargetExplosionRadiusComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const auto RadiusComponent = Cast<UPinballBossTargetExplosionRadiusComponent>(Component);
		if(RadiusComponent == nullptr)
			return;

		const FVector LocationOnPlane = RadiusComponent.WorldLocation.VectorPlaneProject(FVector::ForwardVector);
		DrawCircle(LocationOnPlane, RadiusComponent.Radius, FLinearColor::Red, 10, FVector::ForwardVector);
		DrawCircle(RadiusComponent.WorldLocation, RadiusComponent.Radius, FLinearColor::Red, 10, FVector::ForwardVector);
	}
};
#endif