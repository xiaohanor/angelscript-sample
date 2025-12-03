UCLASS(Abstract)
class USkylineRollingTrashEventHandler : UHazeEffectEventHandler
{
	ASkylineRollingTrash RollingCan;
	float RollingVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		 RollingCan = Cast<ASkylineRollingTrash>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRolling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopRolling() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		RollingVelocity = RollingCan.FauxTranslationComp.GetVelocity().Size();
		RollingVelocity *= 0.005;
		RollingVelocity = Math::Clamp(RollingVelocity,0,1);

		Print(""+RollingVelocity);
	}

};