UCLASS(Abstract)
class ASkylineDroneBossAttachment : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;
	default HealthComponent.MaxHealth = 0.7;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	ASkylineDroneBoss Boss;

	float ActivationTimestamp;
	float DeactivationTimestamp;
	private TArray<FInstigator> Activators;

	void Activate(FInstigator Instigator) 
	{
		Activators.Add(Instigator);

		if (Activators.Num() == 1)
		{
			ActivationTimestamp = Time::GameTimeSeconds;
		}
	}

	void Deactivate(FInstigator Instigator)
	{
		Activators.Remove(Instigator);

		if (Activators.Num() == 0)
		{
			DeactivationTimestamp = Time::GameTimeSeconds;
		}
	}

	bool IsActivated() const
	{
		return Activators.Num() != 0;
	}

	void DestroyAttachment()
	{
		FSkylineDroneBossAttachmentDestroyedData DestroyedData;
		DestroyedData.Attachment = this;
		DestroyedData.Location = ActorLocation;
		USkylineDroneBossEventHandler::Trigger_AttachmentDestroyed(Boss, DestroyedData);

		DestroyActor();
	}
}