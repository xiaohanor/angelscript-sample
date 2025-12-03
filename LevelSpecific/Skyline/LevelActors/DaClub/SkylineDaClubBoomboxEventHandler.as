UCLASS(Abstract)
class USkylineDaClubBoomboxEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Static() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChannelOne() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChannelTwo() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChannelThree() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChannelFour() {}
};