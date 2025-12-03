class ASkylineLevelScriptActor : AHazeLevelScriptActor
{
	UFUNCTION(Meta = (MixinArgument = "Target"))
	void CallSnapActivated(AActor Target)
	{
		auto InterfaceComp = USkylineInterfaceComponent::Get(Target);
		if (InterfaceComp == nullptr)
			return;

		InterfaceComp.OnSnapActivated.Broadcast(Target);
	}

	UFUNCTION(Meta = (MixinArgument = "Target"))
	void CallSnapDeactivated(AActor Target)
	{
		auto InterfaceComp = USkylineInterfaceComponent::Get(Target);
		if (InterfaceComp == nullptr)
			return;

		InterfaceComp.OnSnapDeactivated.Broadcast(Target);
	}

	UFUNCTION(BlueprintCallable)
	void PostCutsceneSetActorVelocity(AHazePlayerCharacter Player, FVector Velocity)
	{
		Player.SetActorVelocity(Velocity);
	}
}