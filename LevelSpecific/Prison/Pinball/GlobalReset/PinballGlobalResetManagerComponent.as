UCLASS(NotBlueprintable, NotPlaceable)
class UPinballGlobalResetManager : UActorComponent
{
	TArray<UPinballGlobalResetComponent> GlobalResetComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		check(Owner == UPinballGlobalResetManager::GetHostPlayer());

		if(Pinball::bUseFastGameOver)
		{
			auto PlayerHealthComp = UPlayerHealthComponent::Get(Owner);
			PlayerHealthComp.CustomGameOverOverride.AddUFunction(this, n"CustomGameOverOverride");
		}
	}

	UFUNCTION()
	private void CustomGameOverOverride()
	{
		for(int i = GlobalResetComponents.Num() - 1; i >= 0; i--)
		{
			auto GlobalResetComponent = GlobalResetComponents[i];
			GlobalResetComponent.PreActivateProgressPoint.Broadcast();
		}

		FString ProgressPoint;

		if(Save::HasSaveToRestartFrom())
		{
			FHazeProgressPointRef SaveChapter;
			FHazeProgressPointRef SavePoint;
			Save::GetSaveToRestart(SaveChapter, SavePoint);
			ProgressPoint = Progress::GetProgressPointRefID(SavePoint);
		}
		else
		{
			check(false, "What do we do here?");
		}

		Progress::PrepareProgressPoint(ProgressPoint);
		Progress::ActivateProgressPoint(ProgressPoint, false);

		for(int i = GlobalResetComponents.Num() - 1; i >= 0; i--)
		{
			auto GlobalResetComponent = GlobalResetComponents[i];
			GlobalResetComponent.PostActivateProgressPoint.Broadcast();
		}
	}
};

namespace UPinballGlobalResetManager
{
	UPinballGlobalResetManager Get()
	{
		return UPinballGlobalResetManager::GetOrCreate(GetHostPlayer());
	}

	AHazePlayerCharacter GetHostPlayer()
	{
		if (Network::IsGameNetworked())
		{
			for(auto Player : Game::Players)
			{
				// GameOver is controlled by the host player
				if (Network::HasWorldControl())
				{
					if (Player.HasControl())
						return Player;
				}
				else
				{
					if (!Player.HasControl())
						return Player;
				}
			}
		}
		else
		{
			// In local we just have Mio control gameover
			return Game::Mio;
		}

		return nullptr;
	}
};