class USmasherMeleeComponent : USceneComponent
{
	default RelativeLocation = FVector(150.0, 0.0, 250.0);

	bool CanHit(AHazePlayerCharacter Target, float HitRadius) const
	{
#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(WorldLocation, HitRadius, 12, FLinearColor::Red, 5.0);
#endif		
		auto AttackShape = FCollisionShape();
		AttackShape.SetSphere(HitRadius);
		return Overlap::QueryShapeOverlap(AttackShape, WorldTransform, Target.CapsuleComponent.GetCollisionShape(), Target.ActorTransform);
	}

	FVector GetImpactImpulse(FVector HitLoc, float Distance, float Height) const
	{
		FVector Impulse = GetImpactHorizontalDirection(HitLoc) * Distance + FVector(0.0, 0.0, Height);
#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugLine(HitLoc, HitLoc + Impulse, FLinearColor::Red, 5.0, 2.0);
#endif		
		return Impulse;	
	}

	FVector GetImpactHorizontalDirection(FVector HitLoc) const
	{
		FVector FromCenter = HitLoc - WorldLocation;
		if (ForwardVector.DotProduct(FromCenter) < 0.0)
			return UpVector.GetSafeNormal2D(); // Behind palm, impact hurls target outward
		if (UpVector.DotProduct(FromCenter) < 0.0)
			return ForwardVector.GetSafeNormal2D(); // Inside palm, throw forward (target should not be drawn towards the smasher)
		// In front and outside of palm, push away
		return FromCenter.GetSafeNormal2D();	
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		if (HazeOwner == nullptr)
			return;
		Debug::DrawDebugSphere(WorldLocation, USmasherSettings::GetSettings(HazeOwner).AttackHitRadius, 12, FLinearColor::Yellow);
	}
#endif
};
