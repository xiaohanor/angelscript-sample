class UBasicAIControlSideSwitchComponent : UActorComponent
{
	AActor WantedController = nullptr;

	void Clear()
	{
		WantedController = nullptr;
	}
}
