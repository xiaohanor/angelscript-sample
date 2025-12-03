class UMeltdownRopeHangPlayerComponent : UActorComponent
{
	bool bRopeHangActive = false;
	USceneComponent ActiveAttachment;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};