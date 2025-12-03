namespace LightSeekerStatics
{
	UFUNCTION(BlueprintCallable)
	ULightSeekerStaticsComponent GetManager()
	{
		ULightSeekerStaticsComponent Manager = ULightSeekerStaticsComponent::Get(Game::Mio);
		
		if(Manager == nullptr)
			Manager = ULightSeekerStaticsComponent::Create(Game::Mio);

		return Manager;
	}
}

event void FLightSeekerStaticFirstEmerge();
class ULightSeekerStaticsComponent : UActorComponent
{
	UPROPERTY(BlueprintReadWrite)
	FLightSeekerStaticFirstEmerge OnFirstLightSeekerEmerge;

	bool bAnyLightseekerEmerged = false;
};