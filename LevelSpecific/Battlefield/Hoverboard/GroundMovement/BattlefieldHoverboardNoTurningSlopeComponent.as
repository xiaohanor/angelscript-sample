class UBattlefieldHoverboardNoTurningSlopeComponent : UActorComponent
{
	
};
#if EDITOR
class UBattlefieldHoverboardNoTurningSlopeComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UBattlefieldHoverboardNoTurningSlopeComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UBattlefieldHoverboardNoTurningSlopeComponent>(Component);

		if((Comp == nullptr) 
		|| (Comp.Owner == nullptr))
			return;

		SetRenderForeground(false);
		
		FVector BoundsLocation;
		FVector BoundsExtents;
		Comp.Owner.GetActorLocalBounds(false, BoundsLocation, BoundsExtents, false);

		BoundsExtents *= Comp.Owner.ActorScale3D;
		BoundsLocation = Comp.Owner.ActorTransform.TransformPosition(BoundsLocation);
		DrawWireBox(BoundsLocation, BoundsExtents, Comp.Owner.ActorQuat, FLinearColor::Red, 50);
	}
}
#endif