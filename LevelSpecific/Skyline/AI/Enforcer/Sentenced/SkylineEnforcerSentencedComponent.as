event void FSkylineEnforcerSentencedComponentSentenceEvent(AHazeActorSpawnerBase Spawner);

class USkylineEnforcerSentencedComponent : UActorComponent
{
	UBasicAIHealthComponent HealthComp;
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY()
	FSkylineEnforcerSentencedComponentSentenceEvent OnSentenced;
	FSkylineEnforcerSentencedComponentSentenceEvent OnPassiveSentenced;

	bool bSentenced;
	bool bPassiveSentenced;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}
	
	UFUNCTION()
	private void OnRespawn()
	{
		bSentenced = false;
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		Sentence();
		PassiveSentence();
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		Sentence();
		PassiveSentence();
	}

	void Sentence()
	{
		if(!Owner.HasActorBegunPlay())
			return;
		if(bSentenced)
			return;

		bSentenced = true;
		OnSentenced.Broadcast(Cast<AHazeActorSpawnerBase>(RespawnComp.Spawner));
	}

	void PassiveSentence()
	{
		if(!Owner.HasActorBegunPlay())
			return;
		if(bPassiveSentenced)
			return;

		bPassiveSentenced = true;
		OnPassiveSentenced.Broadcast(Cast<AHazeActorSpawnerBase>(RespawnComp.Spawner));
	}
}