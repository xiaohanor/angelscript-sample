/**
 * Will make players ignore any collisions with this actor or components on it.
 * FB TODO: Next project, make this possible with channels instead.
 */
UCLASS(NotBlueprintable)
class UPlayerIgnoreActorCollisionComponent : UActorComponent
{
	access EditDefaults = protected, * (editdefaults);
	
	UPROPERTY(EditAnywhere, Category = "Player Ignore Collision Component")
	access:EditDefaults EHazeSelectPlayer PlayersToIgnoreThis;

	UPROPERTY(EditAnywhere, Category = "Player Ignore Collision Component")
	access:EditDefaults bool bIgnoreActor = true;

	UPROPERTY(EditAnywhere, Category = "Player Ignore Collision Component", Meta = (GetOptions="GetComponentNames", EditCondition = "!bIgnoreActor"))
	access:EditDefaults TArray<FName> ComponentsNamesToIgnore;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		const TArray<AHazePlayerCharacter> Players = Game::GetPlayersSelectedBy(PlayersToIgnoreThis);
		for(AHazePlayerCharacter Player : Players)
		{
			if(Player == nullptr)
				continue;

			auto MoveComp = UPlayerMovementComponent::Get(Player);
			if(MoveComp == nullptr)
				continue;

			if(bIgnoreActor)
			{
				MoveComp.AddMovementIgnoresActor(this, Owner);
			}
			else
			{
				TArray<UPrimitiveComponent> ComponentsToIgnore;
				ComponentsToIgnore.Reserve(ComponentsNamesToIgnore.Num());
				for(const FName& ComponentName : ComponentsNamesToIgnore)
				{
					auto Primitive = UPrimitiveComponent::Get(Owner, ComponentName);
					if(Primitive == nullptr)
						continue;

					ComponentsToIgnore.Add(Primitive);
				}

				if(!ComponentsToIgnore.IsEmpty())
					MoveComp.AddMovementIgnoresComponents(this, ComponentsToIgnore);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		const TArray<AHazePlayerCharacter> Players = Game::GetPlayersSelectedBy(PlayersToIgnoreThis);
		for(AHazePlayerCharacter Player : Players)
		{
			if(Player == nullptr)
				continue;

			auto MoveComp = UPlayerMovementComponent::Get(Player);
			if(MoveComp == nullptr)
				continue;

			if(bIgnoreActor)
				MoveComp.RemoveMovementIgnoresActor(this);
			else
				MoveComp.RemoveMovementIgnoresComponents(this);
		}
	}

#if EDITOR
	UFUNCTION()
	private TArray<FName> GetComponentNames() const
	{
		return Editor::GetAllEditorComponentNamesOfClass(Owner, UPrimitiveComponent);
	}
#endif
};