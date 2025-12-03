// Holds a reference to all ceiling climbs in the level
UCLASS(NotBlueprintable, NotPlaceable)
class UTundraPlayerSnowMonkeyCeilingClimbDataComponent : UActorComponent
{
	TArray<UTundraPlayerSnowMonkeyCeilingClimbComponent> AllCeilings;

	bool IsSnowMonkeyWithinDistanceToCeiling(FTundraPlayerSnowMonkeyCeilingData&out OutCeilingData, float Distance) const
	{
		float ClosestDistance = MAX_flt;
		FVector ClosestClosestPoint;
		bool bFoundCeiling = false;

		for(int i = 0; i < AllCeilings.Num(); i++)
		{
			if(AllCeilings[i].IsDisabled())
				continue;

			FTundraPlayerSnowMonkeyCeilingData CeilingData = AllCeilings[i].GetCeilingData();

			const FVector ClosestPoint = CeilingData.GetClosestPointOnCeiling(TopOfPlayerCapsule);
			const float DistanceToCeiling = ClosestPoint.Distance(TopOfPlayerCapsule);

			if(DistanceToCeiling <= Distance && DistanceToCeiling < ClosestDistance)
			{
				ClosestClosestPoint = ClosestPoint;
				ClosestDistance = DistanceToCeiling;
				OutCeilingData = CeilingData;
				bFoundCeiling = true;
			}
		}

		// if(bFoundCeiling)
		// {
		// 	Debug::DrawDebugSphere(TopOfPlayerCapsule, 50.0, 12, FLinearColor::Green, 5.0);
		// 	Debug::DrawDebugSphere(ClosestClosestPoint, 50.0, 12, FLinearColor::Red, 5.0);
		// 	PrintToScreen(f"{ClosestDistance=}");
		// }

		return bFoundCeiling;
	}

	FVector GetTopOfPlayerCapsule() const property
	{
		return Owner.ActorLocation + FVector::UpVector * TundraShapeshiftingStatics::SnowMonkeyCollisionSize.Y * 2.0;
	}
}