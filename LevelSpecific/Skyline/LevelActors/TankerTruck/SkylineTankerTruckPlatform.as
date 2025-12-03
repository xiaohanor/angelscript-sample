class ASkylineTankerTruckPlatform : AHazeActor
{
	private bool bCurrentlyInAcid = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Debug::DrawDebugString(ActorTransform.TransformPosition(FVector(0, 0, -650)), f"{ActorRotation.Roll}");

		float Roll = ActorRotation.Roll;
		bool bIsInAcid = Math::Abs(Math::FindDeltaAngleDegrees(Roll, 0)) < 75;
		if (bIsInAcid)
		{
			// Debug::DrawDebugSphere(
			// 	ActorTransform.TransformPosition(FVector(0, 0, -650)),
			// 	333.0
			// );

			if (!bCurrentlyInAcid)
			{
				USkylineTankerTruckPlatformEffectHandler::Trigger_OnEnterAcid(this);
				bCurrentlyInAcid = true;
			}
		}
		else
		{
			if (bCurrentlyInAcid)
			{
				USkylineTankerTruckPlatformEffectHandler::Trigger_OnExitAcid(this);
				bCurrentlyInAcid = false;
			}
		}
	}
};

UCLASS(Abstract)
class USkylineTankerTruckPlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterAcid() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitAcid() {}
}