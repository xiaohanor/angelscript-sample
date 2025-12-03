namespace LevelEditor
{

bool GetActorPlacementPositionAtCursor(FVector&out OutLocation, FQuat&out OutRotation)
{
	FVector RayOrigin;
	FVector RayDirection;
	if (!Editor::GetEditorCursorRay(RayOrigin, RayDirection))
		return false;

	FHazeTraceSettings Trace;
	Trace.TraceWithChannel(ECollisionChannel::ECC_Visibility);
	Trace.UseLine();

	FHitResult Hit = Trace.QueryTraceSingle(RayOrigin, RayOrigin + RayDirection * 100000.0);
	if (Hit.bBlockingHit)
	{
		OutLocation = Hit.Location;

		FVector RightVector = Hit.ImpactNormal.CrossProduct(FVector::UpVector).GetSafeNormal();
		if (RightVector.IsNearlyZero())
		{
			OutRotation = FQuat::MakeFromXZ(FVector::ForwardVector, Hit.ImpactNormal);
		}
		else
		{
			OutRotation = FQuat::MakeFromXZ(RightVector.CrossProduct(Hit.ImpactNormal), Hit.ImpactNormal);
		}
		return true;
	}
	else
	{
		OutLocation = RayOrigin + RayDirection * 1000.0;
		OutRotation = FQuat::MakeFromXZ(FVector::ForwardVector, FVector::UpVector);
		return true;
	}
}

}