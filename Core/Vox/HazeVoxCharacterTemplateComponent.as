
UFUNCTION(Category = "HazeVox", BlueprintPure)
mixin UHazeVoxCharacterTemplate GetVoxCharacterTemplate(AHazeActor HazeActor)
{
	auto Component = UHazeVoxCharacterTemplateComponent::Get(HazeActor);
	if (Component != nullptr)
	{
		return Component.CharacterTemplate;
	}

	return nullptr;
}

class UHazeVoxCharacterTemplateComponent : UActorComponent
{
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	UHazeVoxCharacterTemplate CharacterTemplate;
}
