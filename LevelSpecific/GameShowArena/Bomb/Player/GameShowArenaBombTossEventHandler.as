struct FGameShowArenaTryCatchBombStartedEventParams
{
	UPROPERTY()
	float MaxCatchRadius;

	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FGameShowArenaTryCatchBombActiveEventParams
{
	UPROPERTY()
	float MaxCatchRadius;

	UPROPERTY()
	FVector Origin;

	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FGameShowArenaBombCatchFailedEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}


struct FGameShowArenaTryCatchBombStoppedEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FGameShowArenaBombCaughtEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	AGameShowArenaBomb Bomb;
}

struct FGameShowArenaPlayerBombExplodedParams
{
	FGameShowArenaPlayerBombExplodedParams(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FGameShowArenaPlayerHurtByFlamesParams
{
	FGameShowArenaPlayerHurtByFlamesParams(AHazePlayerCharacter Player)
	{
		HurtPlayer = Player;
	}
	UPROPERTY()
	AHazePlayerCharacter HurtPlayer;
}

struct FGameShowArenaPlayerLaunchedByLaunchpadParams
{
	FGameShowArenaPlayerLaunchedByLaunchpadParams(AHazePlayerCharacter Player)
	{
		LaunchedPlayer = Player;
	}
	UPROPERTY()
	AHazePlayerCharacter LaunchedPlayer;
}

struct FGameShowArenaBombPickedUpParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	AGameShowArenaBomb Bomb;
}

struct FGameShowArenaPlayerThrowBombAtPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter ThrowingPlayer;

	UPROPERTY()
	AGameShowArenaBomb Bomb;
}

struct FGameShowArenaPlayerThrowBombNoTargetParams
{
	UPROPERTY()
	AHazePlayerCharacter ThrowingPlayer;

	UPROPERTY()
	AGameShowArenaBomb Bomb;
}

UCLASS(Abstract)
class UGameShowArenaBombTossEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	UGameShowArenaBombTossPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UGameShowArenaBombTossPlayerComponent::Get(Player);
	}

	/** Triggers once when player starts trying to catch bomb. Called on the player catching the bomb. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerTryCatchStarted(FGameShowArenaTryCatchBombStartedEventParams Params)
	{
	}

	/** Triggers continuously while player is trying to catch bomb. Called on the player catching the bomb. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerTryCatchActive(FGameShowArenaTryCatchBombActiveEventParams Params)
	{
	}

	/** Triggers once if the player is target of a bomb and didn't catch it after trying. Called on the player catching the bomb. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerBombCatchFailed(FGameShowArenaBombCatchFailedEventParams Params)
	{
	}

	/** Triggers once when player catch ability stops. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerTryCatchStopped(FGameShowArenaTryCatchBombStoppedEventParams Params)
	{
	}

	/** Triggers once if player successfully caught bomb after trying. Called on the player catching the bomb. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerCaughtBomb(FGameShowArenaBombCaughtEventParams Params)
	{
	}

	/** Triggers when a bomb explodes. Called on all players.*/
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerBombExploded(FGameShowArenaPlayerBombExplodedParams Params)
	{
	}

	/** Triggers when player throws bomb at other player. Called on the player throwing the bomb. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerThrowBombAtOtherPlayer(FGameShowArenaPlayerThrowBombAtPlayerParams Params)
	{
	}

	/** Triggers when player throws bomb without aiming at other player. Called on the player throwing the bomb. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerThrowBombNoTarget(FGameShowArenaPlayerThrowBombNoTargetParams Params)
	{
	}

	/** Triggers when player picks up the bomb from the rope. Called on the player catching the bomb. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerPickedUpBomb(FGameShowArenaBombPickedUpParams Params)
	{
	}

	/** Triggers when player starts taking damage from flamethrowers. Called on the player taking damage. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerHurtByFlames(FGameShowArenaPlayerHurtByFlamesParams Params)
	{
	}

	/** Triggers when player is launched by a launchpad. Called on the player being launched. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLaunchedByLaunchpad(FGameShowArenaPlayerLaunchedByLaunchpadParams Params)
	{
	}
};